#FileUtils.mkdir_p 'db/production'
#FileUtils.cp '../db/production/bra.db', 'db/production/bra.db

# porting to ruby 1.9
#FileUtils.mkdir_p "src/conf"
#code =<<-eo_code
#configatron.attivita = #{configatron.attivita}
#configatron.logging_config.level = :#{configatron.connection.level}
#configatron.connection.mode = :#{configatron.connection.mode}
#configatron.connection.adapter = '#{configatron.connection.adapter}'
#configatron.connection.database = '#{configatron.connection.database}'
#configatron.fatturazione.carta_intestata = #{configatron.fatturazione.carta_intestata}
#configatron.fatturazione.iva_per_cassa = #{configatron.fatturazione.iva_per_cassa}
#configatron.pre_fattura.intestazione = #{configatron.pre_fattura.intestazione}
#configatron.screen.width = #{configatron.screen.width}
#configatron.screen.height = #{configatron.screen.height}
#configatron.logging_config.filename = '#{configatron.logging_config.filename}'
#eo_code
#File.open('src/conf/paperclip.rb', "w") { |f| f.write(code) }

