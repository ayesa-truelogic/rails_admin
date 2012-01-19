module RailsAdmin
  module Config
    module Actions
      class New < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)
        
        register_instance_option :collection do
          true
        end
        
        register_instance_option :http_methods do
          [:get, :post] # NEW / CREATE
        end
        
        register_instance_option :controller do
          
          Proc.new do
            
            if request.get? # NEW
              
              @object = @abstract_model.new
              @object.only_when_new if @object.respond_to?(:only_when_new)
              @authorization_adapter && @authorization_adapter.attributes_for(:new, @abstract_model).each do |name, value|
                @object.send("#{name}=", value)
              end
              if object_params = params[@abstract_model.to_param]
                @object.set_attributes(@object.attributes.merge(object_params), _attr_accessible_role)
              end
              respond_to do |format|
                format.html { render @action.template_name }
                format.js   { render @action.template_name, :layout => false }
              end
              
            elsif request.post? # CREATE
              
              @modified_assoc = []
              @object = @abstract_model.new
              @attributes = get_attributes              
              @model_config.create.fields.each {|f| f.parse_input(@attributes) if f.respond_to?(:parse_input) }
              @authorization_adapter && @authorization_adapter.attributes_for(:create, @abstract_model).each do |name, value|
                @object.send("#{name}=", value)
              end
              @object.set_attributes(@attributes, _attr_accessible_role)

              if @object.save
                @auditing_adapter && @auditing_adapter.create_object("Created #{@model_config.with(:object => @object).object_label}", @object, @abstract_model, _current_user)
                respond_to do |format|
                  format.html { redirect_to_on_success }
                  format.js   { render :json => { :id => @object.id, :label => @model_config.with(:object => @object).object_label } }
                end
              else
                handle_save_error
              end
              
            end
          end
        end
      end
    end
  end
end
