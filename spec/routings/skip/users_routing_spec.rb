require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Skip::UsersController do
  describe "route generation" do
    it "should map #sync" do
      route_for(:controller => "skip/users", :action => "sync").should == {:path => "/skip/user/sync", :method => "POST"}
    end

    it "should map #create" do
      route_for(:controller => "skip/users", :action => "create").should == {:path => "/skip/user", :method => "POST"}
    end

    it "should map #update" do
      route_for(:controller => "skip/users", :action => "update").should == {:path => "/skip/user", :method => "PUT"}
    end

    it "should map #destroy" do
      route_for(:controller => "skip/users", :action => "destroy").should == {:path => "/skip/user", :method => "DELETE" }
    end
  end

  describe "route recognition" do
    it "should generate params for #sync" do
      params_from(:post, "/skip/user/sync").should == {:controller => "skip/users", :action => "sync"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/skip/user").should == {:controller => "skip/users", :action => "create"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/skip/user").should == {:controller => "skip/users", :action => "update"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/skip/user").should == {:controller => "skip/users", :action => "destroy"}
    end
  end
end
