module ApplicationHelper

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)", :href => "javascript;;")
  end
  
  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, raw("add_fields(this, '#{association}', '#{escape_javascript(fields)}')") )
  end


  def checked?(value) 
    (value == 1 || value == 'on') ? true : false
  end

  def parts(values, idx)
    return values.values[idx] rescue nil
  end

  def yaml_data(yaml_string)
    YAML::load(yaml_string) rescue {}
  end

  def return_time(value)
    result = yaml_data(value).values
    Time.new(result[0], result[1], result[2], result[3], result[4]) rescue Time.now
  end

end
