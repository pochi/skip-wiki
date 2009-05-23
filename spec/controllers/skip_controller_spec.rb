require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SkipController do
  before do
    controller.should_receive(:check_secret_key).and_return true
  end

  describe "POST :create (success)" do
    before do
      post :create, :format => "js", :skip => {
              :url => "http://skip.example.com",
            }
    end
    it("response should be success"){ response.should be_success }

    describe "created client_application" do
      subject { assigns[:client_application] }

      it { should be_granted_by_service_contract }
      it { should_not be_new_record }
      it { subject.name.should == Skip::ApplicationController::SKIP_NAME }
      it { subject.key.should_not be_blank }
      it { subject.secret.should_not be_blank }
    end

    describe "parse response" do
      subject { JSON.parse(response.body)["skip"] }

      it { subject["id"].should == assigns[:client_application].id }
      it { subject["key"].should_not be_blank }
      it { subject["secret"].should_not be_blank }
    end

    describe "登録後に再度アクセスされた場合" do
      before do
        controller.should_receive(:check_secret_key).and_return true
        @exist = ClientApplication.find_by_name("SKIP")
        post :create, :format => "js", :skip => {
                :url => "http://skip.example.com",
              }
      end
      it("response should be Conflict"){ response.message.should == "Conflict"  }
    end
  end
end
