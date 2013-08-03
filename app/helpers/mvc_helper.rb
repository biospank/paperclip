# encoding: utf-8

module Helpers
  # questo modulo puo' essere esteso da classi o da altri moduli
  # class.extend ModelHelper / module.extend ModelHelper
  module MVCHelper
    def model(names)
      names.each_pair do |name, opts|
        instance_eval %{
          #require "app/models/#{name.to_s}"

          # inizializzo il modello
          @#{name.to_s} = Models::#{name.to_s.camelize}.new

          # attributi del modello
          @#{name.to_s}_attrs = eval('opts[:attrs]')

          # mantiene l'associazione tra l'attributo del modello (key)
          # e il widget corrispondente (value)
          @map_fields = {}

          # accessors utility
          def #{name.to_s}()
            @#{name.to_s}
          end

          def #{name.to_s}=(obj)
            @#{name.to_s} = obj
          end

#            alias :instance_model :#{name.to_s}
#            alias :instance_model= :#{name.to_s}=

          def mapped_fields(sym)
            var = @map_fields[sym]
            self.instance_variable_get(var) if var
          end

          def focus_#{name.to_s}_error_field()
            field = mapped_fields(#{name.to_s}.error_field)
            field.activate() if field
          end


          def transfer_#{name.to_s}_to_view(my_model = nil)
            begin
              if my_model
                self.instance_variables.each do |var| 

                  obj = self.instance_variable_get(var)

                  if obj.respond_to?(:view_data=)
                    if match_data = var.to_s.match(/_/)
                      field = match_data.post_match
                      if @#{name.to_s}_attrs.empty?
                        @map_fields[field.to_sym] = var
                        #logger.debug('writing: ' + field)
                        obj.view_data = my_model.send(field.to_sym)
                        #logger.debug('view_data: ' + obj.view_data.to_s)
                      else
                        if @#{name.to_s}_attrs.include? field.to_sym
                          @map_fields[field.to_sym] = var
                          #logger.debug('writing: ' + field)
                          obj.view_data = my_model.send(field.to_sym)
                          #logger.debug('view_data: ' + obj.view_data.to_s)
                        end
                      end
                    end
                  end

                end
              else
                self.instance_variables.each do |var| 

                  obj = self.instance_variable_get(var)

                  if obj.respond_to?(:view_data=)
                    if match_data = var.to_s.match(/_/)
                      field = match_data.post_match
                      if @#{name.to_s}_attrs.empty?
                        @map_fields[field.to_sym] = var
                        #logger.debug('writing: ' + field)
                        obj.view_data = @#{name.to_s}.send(field.to_sym)
                        #logger.debug('view_data: ' + obj.view_data.to_s)
                      else
                        if @#{name.to_s}_attrs.include? field.to_sym
                          @map_fields[field.to_sym] = var
                          #logger.debug('writing: ' + field)
                          obj.view_data = @#{name.to_s}.send(field.to_sym)
                          #logger.debug('view_data: ' + obj.view_data.to_s)
                        end
                      end
                    end
                  end

                end
              end
            rescue Exception => e
              logger.error('Error: ' + e.message)
              logger.error('Backtrace: ' + "\n" + e.backtrace.join("\n")) if e.backtrace
              raise e
            end
          end

          def transfer_#{name.to_s}_from_view()
            begin
              self.instance_variables.each do |var| 

                obj = self.instance_variable_get(var)

                if obj.respond_to? :view_data
                  if match_data = var.to_s.match(/_/)
                    if @#{name.to_s}_attrs.empty?
                      @map_fields[match_data.post_match.to_sym] = var
                      field = match_data.post_match << '='
                      #logger.debug('reading: ' + field)
                      @#{name.to_s}.send(field.to_sym, obj.view_data)
                    else
                      if @#{name.to_s}_attrs.include? match_data.post_match.to_sym
                        @map_fields[match_data.post_match.to_sym] = var
                        field = match_data.post_match << '='
                        #logger.debug('reading: ' + field)
                        @#{name.to_s}.send(field.to_sym, obj.view_data)
                        #logger.debug('view_data: ' + obj.view_data.to_s)
                      end
                    end
                  end
                end

              end
            rescue Exception => e
              logger.error('Error: ' + e.message)
              logger.error('Backtrace: ' + "\n" + e.backtrace.join("\n")) if e.backtrace
              raise e
            end
          end

          def reset_#{name.to_s}()
            @#{name.to_s} = Models::#{name.to_s.camelize}.new
            transfer_#{name.to_s}_to_view()
          end

        }

#        module_eval %{
#          def load_#{name.to_s}(id)
#            Models::#{name.to_s.camelize}.find(id)
#          end
#
#          def save_#{name.to_s}()
#            #{name.to_s}.save
#          end
#
#          def delete_#{name.to_s}()
#            #{name.to_s}.destroy
#          end
#
#        }
#        
        if opts[:alias]
          instance_eval %{
            alias #{opts[:alias]} #{name.to_s}
            alias #{opts[:alias]}= #{name.to_s}=
            alias transfer_#{opts[:alias]}_to_view transfer_#{name.to_s}_to_view
            alias transfer_#{opts[:alias]}_from_view transfer_#{name.to_s}_from_view
            alias reset_#{opts[:alias]} reset_#{name.to_s}
            alias focus_#{opts[:alias]}_error_field focus_#{name.to_s}_error_field
          }
        end
      end
        
    end

    def controller(name)
      instance_eval %{
        require "app/controllers/#{name.to_s}_controller.rb"

        extend Controllers::#{name.to_s.camelize}Controller

        # accessor utility
        def ctrl()
          self
        end

      }
    
    end

  end
end