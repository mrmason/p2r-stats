class CompanyInfo < ActiveRecord::Base
  attr_accessible :company_id, :votes
  belongs_to :company
  
end
