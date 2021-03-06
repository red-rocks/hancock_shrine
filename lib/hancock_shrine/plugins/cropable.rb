# frozen_string_literal: true

class Shrine
  module Plugins
    # The `cropable` plugin adds crop support
    #     plugin :cropable

    module Cropable

      def self.configure(uploader, opts = {})
        # uploader.opts[:Timestampable] = "LOADED"
      end

      def self.load_dependencies(uploader, *)
        uploader.plugin :add_metadata
        uploader.add_metadata :crop do |io|
          {}
        end
      end


      module InstanceMethods

        def extract_metadata(io, **options)
          metadata = super
          metadata[:crop] = (io && io.data && io.data["metadata"] && io.data["metadata"]["crop"]) rescue nil
          metadata.compact
        end

        def crop_params(target = nil)

          return nil if target.nil?
          return @crop_params if @crop_params
          w = ((target.respond_to?(:crop_w) and target.crop_w) ? target.crop_w.to_i : nil)
          h = ((target.respond_to?(:crop_h) and target.crop_h) ? target.crop_h.to_i : nil)
          x = ((target.respond_to?(:crop_x) and target.crop_x) ? target.crop_x.to_i : nil)
          y = ((target.respond_to?(:crop_y) and target.crop_y) ? target.crop_y.to_i : nil)
          
          @crop_params = if w and h and x and y
            if imagick?
              # IMagick / RMagick / ImageMagick
              x = "+#{x}" if x >= 0
              y = "+#{y}" if y >= 0
              ["#{w}x#{h}#{x}#{y}"]
            elsif vips?
              # VIPS
              [x, y, w, h].map(&:to_i) 
            end
          end
        end

        def cropping(pipeline, io, context)
          _crop_params = crop_params(context[:record]) 
          if _crop_params.blank?
            _crop_params = io.metadata[:crop] || io.metadata["crop"]
            unless _crop_params.blank?
              _crop_params = _crop_params.with_indifferent_access
              _crop_params = [
                _crop_params[:crop_x],
                _crop_params[:crop_y],
                _crop_params[:crop_w],
                _crop_params[:crop_h]
              ]
            end
          end
          unless _crop_params.blank?
            io.metadata[:crop] ||= {
              crop_x: _crop_params[0],
              crop_y: _crop_params[1],
              crop_w: _crop_params[2],
              crop_h: _crop_params[3],
            }
            pipeline = pipeline.crop(*_crop_params)
          end          
          pipeline
        end
        
      end


      module AttacherClassMethods
        
        def dump(attacher)
          super.merge(
            {
              "crop_params"  => attacher.store.crop_params(attacher.record)
            }
          )
          ##############################
          # attacher.dump.merge(
          #   {
          #     "crop_params"  => attacher.store.crop_params(attacher.record)
          #   }
          # )
        end
    
        def load_record(data)
          record = super
          if data["crop_params"]
            # [x, y, w, h].map(&:to_i) 
            record.crop_x = data["crop_params"][0]
            record.crop_y = data["crop_params"][1]
            record.crop_w = data["crop_params"][2]
            record.crop_h = data["crop_params"][3]
          end
          record
          ##############################
          # record_class, record_id = data["record"]
          # record_class = Object.const_get(record_class)
    
          # if respond_to?(:find_record)
          #   record   = find_record(record_class, record_id)
          #   record ||= record_class.new.tap do |instance|
          #     # so that the id is always included in file deletion logs
          #     instance.singleton_class.send(:define_method, :id) { record_id }
          #   end
          # else
          #   record = record_class.new
          #   record.send(:"#{data["name"]}_data=", data["attachment"])
          # end
          # if data["crop_params"]
          #   # [x, y, w, h].map(&:to_i) 
          #   record.crop_x = data["crop_params"][0]
          #   record.crop_y = data["crop_params"][1]
          #   record.crop_w = data["crop_params"][2]
          #   record.crop_h = data["crop_params"][3]
          # end
    
          # record
        end
        
      end
    end

    register_plugin(:cropable, Cropable)
  end
end
