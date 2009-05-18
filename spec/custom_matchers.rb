require 'spec/matchers'

Spec::Matchers.define :be_completed_within do |sec|
  match do |lambda|
    start = Time.now
    lambda.call
    (@real = Time.now - start) < sec
  end

  description do
    "completed in #{expected} sec.".tap{|x| x<<"(#{@real} sec in real)" if (@real && (sec > @real)) }
  end

  failure_message_for_should do |actual|
    "expected to complete in #{sec} sec, but takes #{@real} sec."
  end
end

Spec::Matchers.define :have_authorized_access_token_for do |app|
  description{ "have authorized AccessToken for #{app.to_s}" }

  match do |user|
    t, = app.tokens.find_all_by_type_and_user_id("AccessToken", user)
    t && t.authorized?
  end
end

Spec::Matchers.define :have_invalidated_request_token_for do |app|
  description{ "have invalidated RequestToken for #{app.to_s}" }

  match do |user|
    t, = app.tokens.find_all_by_type_and_user_id("RequestToken", user)
    t && t.invalidated?
  end
end

