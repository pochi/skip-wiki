require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::LabelIndicesController do
  describe "route generation" do
    it "should map #show" do
      route_for(:controller => 'admin/label_indices', :action => 'show', :note_id => 'a_note', :id => "1").should == "/admin/notes/a_note/label_indices/1"
    end
    it "should map #edit" do
      route_for(:controller => 'admin/label_indices', :action => 'edit', :note_id => 'a_note', :id => "1").should == "/admin/notes/a_note/label_indices/1/edit"
    end
    it "should map #update" do
      route_for(:controller => 'admin/label_indices', :action => 'update', :note_id => 'a_note', :id => "1").should == { :path => "/admin/notes/a_note/label_indices/1", :method => "PUT"}
    end
  end

  describe "route recognization" do
    it "should generate params for #show" do
      params_from(:get, "/admin/notes/a_note/label_indices/1").should == {:controller => 'admin/label_indices', :action => 'show', :note_id => 'a_note', :id => "1"}
    end   
    it "should generate params for #edit" do
      params_from(:get, "/admin/notes/a_note/label_indices/1/edit").should == {:controller => 'admin/label_indices', :action => 'edit', :note_id => 'a_note', :id => "1"}    
    end   
    it "should generate params for #update" do
      params_from(:put, "/admin/notes/a_note/label_indices/1").should == {:controller => 'admin/label_indices', :action => 'update', :note_id => 'a_note', :id => "1"}       
    end   
  end
end
