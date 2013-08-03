#require File.join(File.dirname(__FILE__), '../minitest_helper.rb')
require 'minitest_helper.rb'

describe Models::Cliente, "Modello Cliente" do
  before do
    Models::Azienda.current = Models::Azienda.first
    @cliente = Models::Cliente.new()
  end

  after do

  end

  describe "denominazione" do
    before do
      @cliente.valid?
    end

    it "non valorizzata" do
      @cliente.errors.on(:denominazione).must_equal "Inserire la denominazione"
    end
  end

  describe "partita iva" do
    before do
      @cliente.valid?
    end

    it "inesistente" do
      @cliente.errors.on(:p_iva).must_include "Inserire la partita iva"
    end
  end

  describe "partita iva" do
    before do
      @cliente.no_p_iva = false
      @cliente.p_iva = '1234567891'
      @cliente.valid?
    end

    it "deve essere di 11 caratteri senza opzione 'no_p_iva'" do
      if @cliente.no_p_iva?
        @cliente.errors.on(:p_iva).must_equal "La partita iva deve essere di 11 caratteri"
      end
    end
  end

  describe "partita iva" do
    before do
      @cliente.no_p_iva = true
      @cliente.valid?
    end

    it "nessun errore con opzione 'no_p_iva'" do
      if @cliente.no_p_iva?
        @cliente.errors.on(:p_iva).must_be_nil
      end
    end
  end

  describe "codice fiscale" do
    before do
      @cliente.cod_fisc = '1234567891098765'
      @cliente.valid?
    end

    it "deve essere di 16 caratteri" do
      @cliente.cod_fisc.size.must_equal 16
    end
  end

end
