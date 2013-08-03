# encoding: utf-8

#require 'app/helpers/logger_helper'

module Models
  module Base
    module Model
      include Helpers::AuthorizationHelper
      
      def error_msg()
        self.errors.entries.first().last()
      end
      
      def error_field()
        self.errors.entries.first().first().to_sym
      end

      def to_sql_year(column)
        case ActiveRecord::Base.connection.adapter_name().downcase.to_sym
        when :sqlite
          "strftime('%Y', #{column})"
        when :postgresql
          "to_char(#{column}, 'YYYY')"
        end
      end

    end

    module Searchable
      def searchable_by(*column_names)
        @search_columns = []
        [column_names].flatten.each do |name|
          @search_columns << name
        end
      end
      
      def search_for(query=nil, fields=nil, options={})
        with_scope( :find => { :conditions => (query.nil? ? [] : search_conditions(query, fields)) }) do
          if column_names().include? "azienda_id"
            with_scope(:find => { :conditions => ["#{table_name}.azienda_id = ?", Azienda.current] }) do
              find :all, options
            end
          else
            find :all, options
          end
        end
      end

      def search(*args)
        if column_names().include? "azienda_id"
          with_scope(:find => { :conditions => ["#{table_name}.azienda_id = ?", Azienda.current] }) do
            find(*args)
          end
        else
          find(*args)
        end
      end

      def search_conditions(query, fields=nil)
        return nil if query.blank?
        fields ||= @search_columns
        # split the query by commas as well as spaces, just in case
        words = query.split("," ).map(&:split).flatten
        binds = {} # bind symbols
        or_frags = [] # OR fragments
        count = 1 # to keep count on the symbols and OR fragments
        words.each do |word|
          like_frags = [fields].flatten.map { |f| "LOWER(#{f}) LIKE :word#{count}" }
          or_frags << "(#{like_frags.join(" OR ")})"
          binds["word#{count}".to_sym] = "%#{word.to_s.downcase}%"
          count += 1
        end
        [or_frags.join(" AND " ), binds]
      end
        
    end

  end
end