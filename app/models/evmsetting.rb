# evm setting model
class Evmsetting < ActiveRecord::Base
  # Relations
  belongs_to :project

  # Validate
  validates :etc_method,
            presence: true

  validates :basis_hours,
            presence: true,
            numericality: { greater_than: 0 }

  validates :threshold_spi,
            presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 0.99 }

  validates :threshold_cpi,
            presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 0.99 }

  validates :threshold_cr,
            presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 0.99 }

  validates :region,
            presence: true
end
