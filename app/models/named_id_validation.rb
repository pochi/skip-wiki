module NamedIdValidation
  RE = /[A-Za-z0-9_|-]+/
  def validates_named_id_of(column, options = {})
    validates_presence_of column
    validates_format_of column, :with => RE, :message => "use alphabet, '_', and '-' only."
    validates_length_of column, :within => 3..40
    validates_exclusion_of column, :in => %w[new edit]
  end
end
