require 'spec/base/env_helper'
require 'app/models/base'
require 'app/models/azienda'
require 'app/models/dati_azienda'
require 'app/models/cliente'
require 'ruby-debug'

describe Models::Cliente do
  attr_accessor :cliente
  
  before(:all) do
    Models::Azienda.current = Models::Azienda.find(1, :include => :dati_azienda)
    @c = Models::Cliente.create(:denominazione => 'OilCan', :p_iva => '12345678910', :cod_fisc => '12345678910')
    @cliente = Models::Cliente.new()
  end

  before(:each) do
    cliente.errors.clear()
  end

  # DENOMINAZIONE
  it "La denominazione non puo essere nulla" do
    cliente.should_not be_valid
    cliente.errors.on(:denominazione).should_not be_nil
    if cliente.errors.on(:denominazione).is_a? Array
      cliente.errors.on(:denominazione).should include('Inserire la denominazione')
    elsif cliente.errors.on(:denominazione).is_a? String
      cliente.errors.on(:denominazione).should == 'Inserire la denominazione'
    end
  end
  
  it "La denominazione non deve essere vuota" do
    cliente.denominazione = ''
    cliente.should_not be_valid
    cliente.errors.on(:denominazione).should_not be_nil
    if cliente.errors.on(:denominazione).is_a? Array
      cliente.errors.on(:denominazione).should include('Inserire la denominazione')
    elsif cliente.errors.on(:denominazione).is_a? String
      cliente.errors.on(:denominazione).should == 'Inserire la denominazione'
    end
  end

  it "Deve avere una denominazione valida" do
    cliente.denominazione = "OilCan"
    cliente.should_not be_valid
    cliente.errors.on(:denominazione).should be_nil
  end
  
  # PARTITA IVA
  it "La partita iva non puo essere nulla" do
    cliente.should_not be_valid
    cliente.errors.on(:p_iva).should_not be_nil
    if cliente.errors.on(:p_iva).is_a? Array
      cliente.errors.on(:p_iva).should include('Inserire la partita iva')
    elsif cliente.errors.on(:p_iva).is_a? String
      cliente.errors.on(:p_iva).should == 'Inserire la partita iva'
    end
  end
  
  it "La partita iva deve essere di 11 caratteri" do
    cliente.p_iva = "1234567891011"
    cliente.should_not be_valid
    cliente.errors.on(:p_iva).should_not be_nil
    if cliente.errors.on(:p_iva).is_a? Array
      cliente.errors.on(:p_iva).should include('La partita iva deve essere di 11 caratteri')
    elsif cliente.errors.on(:p_iva).is_a? String
      cliente.errors.on(:p_iva).should == 'La partita iva deve essere di 11 caratteri'
    end
  end
  
  it "La partita iva deve essere univoca" do
    cliente.cod_fisc = '12345678910'
    cliente.p_iva = "12345678910"
    cliente.should_not be_valid
    cliente.errors.on(:p_iva).should_not be_nil
    if cliente.errors.on(:p_iva).is_a? Array
      cliente.errors.on(:p_iva).should include("La partita iva inserita e' gia' utilizzata")
    elsif cliente.errors.on(:p_iva).is_a? String
      cliente.errors.on(:p_iva).should == "La partita iva inserita e' gia' utilizzata"
    end
  end
  
  it "La partita iva puo' essere nulla se e' impostato il flag no_p_iva" do
    cliente.p_iva = nil
    cliente.no_p_iva = true
    cliente.should_not be_valid
    cliente.errors.on(:p_iva).should be_nil
  end
  
  it "Deve avere una partita iva" do
    cliente.p_iva = "12345678919"
    cliente.should_not be_valid
    cliente.errors.on(:p_iva).should be_nil
  end
  
  # CODICE FISCALE
  it "Il codice fiscale non puo essere nullo" do
    cliente.cod_fisc = ''
    cliente.should_not be_valid
    cliente.errors.on(:cod_fisc).should_not be_nil
    if cliente.errors.on(:cod_fisc).is_a? Array
      cliente.errors.on(:cod_fisc).should include('Inserire il codice fiscale')
    elsif cliente.errors.on(:cod_fisc).is_a? String
      cliente.errors.on(:cod_fisc).should == 'Inserire il codice fiscale'
    end
  end
  
  it "Il codice fiscale deve essere univoco" do
    cliente.cod_fisc = '12345678910'
    cliente.should_not be_valid
    cliente.errors.on(:cod_fisc).should_not be_nil
    if cliente.errors.on(:cod_fisc).is_a? Array
      cliente.errors.on(:cod_fisc).should include("Il codice fiscale inserito e' gia' utilizzato")
    elsif cliente.errors.on(:cod_fisc).is_a? String
      cliente.errors.on(:cod_fisc).should == "Il codice fiscale inserito e' gia' utilizzato"
    end
  end
  
  it "Se numerico il codice fiscale deve essere di 11 caratteri" do
    cliente.cod_fisc = '1234567891011'
    if cliente.cod_fisc.match(/^[0-9]+$/)  
      cliente.should_not be_valid
      cliente.errors.on(:cod_fisc).should_not be_nil
      if cliente.errors.on(:cod_fisc).is_a? Array
        cliente.errors.on(:cod_fisc).should include('Il codice fiscale deve essere di 11 caratteri')
      elsif cliente.errors.on(:cod_fisc).is_a? String
        cliente.errors.on(:cod_fisc).should == 'Il codice fiscale deve essere di 11 caratteri'
      end
    end
  end

  it "Se alfanumerico il codice fiscale deve essere di 16 caratteri" do
    cliente.cod_fisc = '1234567891011'
    unless cliente.cod_fisc.match(/^[0-9]+$/)  
      cliente.should_not be_valid
      cliente.errors.on(:cod_fisc).should_not be_nil
      if cliente.errors.on(:cod_fisc).is_a? Array
        cliente.errors.on(:cod_fisc).should include('Il codice fiscale deve essere di 16 caratteri')
      elsif cliente.errors.on(:cod_fisc).is_a? String
        cliente.errors.on(:cod_fisc).should == 'Il codice fiscale deve essere di 16 caratteri'
      end
    end
  end

  it "Deve avere un codice fiscale numerico" do
    self.cliente = Models::Cliente.new()
    cliente.cod_fisc = "12345678910"
    cliente.should_not be_valid
    cliente.errors.on(:cod_fisc).should be_nil
  end

  it "Deve avere un codice fiscale alfanumerico" do
    self.cliente = Models::Cliente.new()
    cliente.cod_fisc = "PTRFBA71E09H501Z"
    cliente.should_not be_valid
    cliente.errors.on(:cod_fisc).should be_nil
  end

#  it "deve avere un'azienda associata" do
#    cliente.save!.should raise_error ActiveRecord::RecordInvalid, /^ActiveRecord::RecordInvalid/
#  end
#
#  it "Per essere salvata, deve essere valida" do
#    if cliente.valid?
#      cliente.errors.should be_empty
#    else
#      cliente.errors.each do |attr, msg|
#        puts msg
#      end
#      cliente.errors.should be_empty
#    end
#  end
  
#  it "la partita iva non puo' essere duplicata" do
#    @cliente.save!
##    @cliente2.p_iva = "12345678910"
#    @cliente2.should_not be_valid
#    @cliente2.errors.should_not be_empty
#    @cliente2.errors.on(:p_iva).should_not be_empty
#  end
#
#  it "Il codice fiscale non puo' essere duplicato" do
#    @cliente.save!
##    @cliente2.cod_fisc = "PTRFBA71E09H501Z"
#    @cliente2.should_not be_valid
#    @cliente2.errors.should_not be_empty
#    @cliente2.errors.on(:cod_fisc).should_not be_empty
#  end
#
#  after(:each) do 
#    Models::Cliente.delete_all
#  end

  after(:all) do
    @c.destroy()
  end

  
  
end

