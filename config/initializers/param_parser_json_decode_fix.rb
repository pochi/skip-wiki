# actionpack-2.1.2/lib/action_controller/request.rb L.409
ActionController::Base.param_parsers[Mime::JSON] = proc do |body|
  if body.blank?
    {}
  else
    data = JSON.parse(body)
    data = {:_json => data} unless data.is_a?(Hash)
    data.with_indifferent_access
  end
end
