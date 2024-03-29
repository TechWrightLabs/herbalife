class User < ApplicationRecord
  attr_accessor :name

  has_one_attached :certificate

  # validate :check_terms_agreement
  validate :name_length

  def generate_certificate
    if self.partner.blank?
      img = Magick::ImageList.new("#{Rails.root}/db/data/certificate.jpg")
    else
      img = Magick::ImageList.new("#{Rails.root}/db/data/certificate_2.jpg")
    end

    text = Magick::Draw.new
    if self.partner.blank?
      message = <<~INFO
        #{self.first_name}
      INFO
    else
      message = <<~INFO
        #{self.first_name}
        #{self.partner}
      INFO
    end

    img.annotate(text, 0,0,360,-60, message) do
      text.gravity = Magick::WestGravity # Text positioning
      text.pointsize = 210 # Font size
      text.fill = "#bf2571" # Font color
      text.font = "#{Rails.root}/db/data/SnellRoundhand.ttc"
      text.font_weight = 500
      text.font_style = Magick::ItalicStyle
      text.interline_spacing = 4
      img.format = "jpeg"
    end

    tmp_path = "#{Rails.root}/tmp/generated-#{self.id}.jpg"

    img.write(tmp_path)

    self.certificate.attach(io: File.open(tmp_path), filename: "certificate-#{self.id}.jpg")
  end

  private
    def check_terms_agreement
      errors.add(:agreed_to_terms, 'needs to be checked before continuing!') unless self.agreed_to_terms
    end

    def name_length
      if self.first_name.size > 20
        errors.add(:name, 'should be less than 20 characters!')
      elsif self.partner.size > 20
        errors.add(:partner, 'name should be less than 20 characters!')
      end
    end
end
