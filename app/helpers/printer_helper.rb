# encoding: utf-8

require 'singleton'

module Helpers
  class Printer < Wx::HtmlEasyPrinting
    include Singleton
    include Logger
    
    GRID_DEFAULT_ROW_LIMIT = 5
    
    def initialize(name="Stampa", owner=nil)
      super
    end

    def run(opts={})
      # orientation
      self.get_print_data().orientation = opts[:orientation] || Wx::PORTRAIT

      # margins
      self.get_page_setup_data().margin_top_left = opts[:margin_tl] || [15, 15]
      self.get_page_setup_data().margin_bottom_right = opts[:margin_br] || [15, 15]

      # header
      if opts[:header]
        self.set_header(cast_eval(opts[:header][:content]), (opts[:header][:policy] || Wx::PAGE_ALL))
      else
        self.set_header('')
      end
      # footer
      if opts[:footer]
        self.set_footer(cast_eval(opts[:footer][:content]), (opts[:footer][:policy] || Wx::PAGE_ALL))
      else
        self.set_footer('')
      end
      
      # body
      txt = ''
      if grid = opts[:body][:grid]
        set = (grid[:set] || [])
        row_limit = (grid[:row_limit] || GRID_DEFAULT_ROW_LIMIT)
        
        if grid[:col_limit]
          char_limit = grid[:col_limit][:char_limit]
          
          rows = []
          exceed = 0
          count = 0
          
          re = /[a-z\s\.\,-]/
          if grid[:col_limit][:name]
            logger.debug("NAME")
            # lunghezza della colonna per nome
            proc = lambda do |row| 
              column = row.send(grid[:col_limit][:name])
              if (total_char_length = column.length) > 0
                # ricavo la lunghezza della stringa data da carratteri maiuscoli e numeri
                upcase_char_length = column.gsub(re, '').length
                # proporzione per ricavare la percentuale sul totale:
                # lunghezza totale : 100 = lunghezza caratteri maiuscoli : x
                upcase_percent = ((upcase_char_length * 100) / total_char_length)
                # percentuale totale diviso percentuale parziale
                total_char_length += (100 / upcase_percent) unless upcase_percent.zero?
              end
              total_char_length
            end
          elsif grid[:col_limit][:position]
            logger.debug("POSITION")
            # lunghezza della colonna per posizione
            proc = lambda do |row|
              column = row[grid[:col_limit][:position]]
              if (total_char_length = column.length) > 0
                # ricavo la lunghezza della stringa data da carratteri maiuscoli e numeri
                upcase_char_length = column.gsub(re, '').length
                # proporzione per ricavare la percentuale sul totale:
                # lunghezza totale : 100 = lunghezza caratteri maiuscoli : x
                upcase_percent = ((upcase_char_length * 100) / total_char_length)
                # percentuale totale diviso percentuale parziale
                total_char_length += (100 / upcase_percent) unless upcase_percent.zero?
              end
              total_char_length
            end
          end

          logger.debug("row_limit: #{row_limit}")
          logger.debug("char_limit: #{char_limit}")
          set.each_with_index do |row, idx|
            char_length = proc.call(row)

            logger.debug("char_length: #{char_length}")
            
            case char_length
            when 0..char_limit
              exceed += 1
            when (char_limit)..(char_limit * 3)
              exceed += 2
              count += 1
            when (char_limit * 3)..(char_limit * 5)
              exceed += 3
              count += 2
            when (char_limit * 5)..(char_limit * 7)
              exceed += 4
              count += 2
            when (char_limit * 7)..(char_limit * 9)
              exceed += 5
              count += 3
            when (char_limit * 9)..(char_limit * 11)
              exceed += 6
              count += 3
            when (char_limit * 11)..(char_limit * 13)
              exceed += 7
              count += 4
            when (char_limit * 13)..(char_limit * 15)
              exceed += 8
              count += 4
            when (char_limit * 15)..(char_limit * 17)
              exceed += 9
              count += 5
            end

            logger.debug("exceed: #{exceed}")

            if exceed <= row_limit
              rows << row
              txt += cast_eval(grid[:content], rows) if(idx == (set.size - 1))
            else
              logger.debug("rows.size: #{rows.size}")
              logger.debug("(count / 2): #{(count / 2)}")
              if padding = grid[:col_limit][:padding]
                # padding e' sempre a 0 (per chi lo usa)
                # serve solo per non sottrarre la media
                exceed -= padding
              else
                # ripristina una media delle righe eccedenti (vedi sopra)
                exceed -= (count / 2)
              end
              
              if exceed <= row_limit
                count = 0
                redo
              else
                logger.debug("rows.size: #{rows.size}")
                txt += cast_eval(grid[:content], rows)
                txt += '<div style="page-break-before:always"> </div>'
                rows = []
                exceed = 0
                count = 0
                redo
              end
            end
            
          end
          
        else
          0.step(set.size, row_limit) do |i|
            rows = set.slice(i, row_limit)
            txt += cast_eval(grid[:content], rows)
            txt += '<div style="page-break-before:always"> </div>' if((i + row_limit) < set.size)
          end
        end
      end

      txt
      
    end
    
    private

    def cast_eval(what, param=nil)
      case what
      when String
        what
      when Proc 
        what.call(param)
      end
    end

    
  end
end
