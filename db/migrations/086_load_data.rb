class LoadData < ActiveRecord::Migration
  def self.up

    Models::CategoriaPdc.delete_all
    Models::Pdc.delete_all
    Models::Norma.delete_all

    # categorie_pdc, pdc
    execute("insert into categorie_pdc (id, codice, descrizione, type) values (1, 100, 'CREDITI VS.SOCI X VERSAMENTI', 'Attivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 1, 10000, 'CREDITI VS. SOCI RICHIAMATI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 1, 10001, 'CREDITI V/SOCI C/SOTTOSCR.')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (2, 129, 'IMMOBILIZZAZIONI IMMATERIALI', 'Attivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 2, 12901, 'AVVIAMENTO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 2, 13200, 'SOFTWARE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 2, 13201, 'ALTRI ONERI PLURIENNALI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (3, 150, 'IMMOBILIZZAZIONI MATERIALI', 'Attivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15005, 'TERRENI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15200, 'FABBRICATI CIVILI STRUM.')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15400, 'MACCHINARI IMPIANTI SPECIFICI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15430, 'MACCH. E IMPIANTI GENERICI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15431, 'CONDIZIONATORI E DEUMIDIFICAT.')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15432, 'IMPIANTO DI ALLARME')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15433, 'MACCH. APP. E ATTR. VARIE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15600, 'ATTREZZATURA VARIA E MINUTA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15602, 'BENI IN NOLEGGIO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15610, 'STIGLIATURA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15701, 'MOTOCICLI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15710, 'MOBILI E MACCHINE UFFICIO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15712, 'MOBILI E ARREDI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15713, 'IMPIANTI SPECIFICI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15720, 'MACCHINE UFFICIO ELETTRONICHE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15721, 'REGISTRATORE DI CASSA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15740, 'BENI INFERIORI A E.516,46')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15761, 'IMPIANTO TELEFONICO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 3, 15770, 'AUTOMEZZI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (4, 160, 'IMMOBILIZZAZIONI FINANZIARIE', 'Attivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 4, 15005, 'TITOLI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (5, 200, 'ATT. CIRC.: RIMANENZE', 'Attivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 5, 20015, 'RIMANENZA MATERIALE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 5, 20021, 'FATTURE DA EMETTERE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 5, 20400, 'RIM.PRODOTTI IN CORSO DI LAV.')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 5, 20600, 'RIMANENZE FINALI MERCI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (6, 293, 'ATT.CIRC.: CREDITI', 'Attivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29300, 'RIT. ACC.TO 4%')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29499, 'SOCI C/PRELEVAMENTO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29502, 'TITOLARE C/PRELEV.')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29503, 'EFFETTI IN PORTAFOGLIO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29505, 'ERARIO C/RIT.ATTIVE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29515, 'RIT. FISCALE DA BANCHE E PT')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29534, 'ERARIO C/ACC.TO IRAP')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29535, 'ERARIO C/IRAP DA COMPENSARE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29543, 'ERARIO C/ACC.IMPOSTA SOST.1712')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29544, 'ERARIO C/ACC.TO INAIL')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29547, 'ERARIO C/ACC.TO IRES DA COMP.')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 29596, 'ERARIO C/ACC.TO IRES')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 30000, 'IVA C/ERARIO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 30001, 'IVA C/ERARIO IN SOSPESO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 30002, 'IVA C/ERARIO DETR.A FINE ANNO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 6, 30005, 'ERARIO C/IVA DA COMPENSARE')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (7, 330, 'ATT.CIRC.: DISPONIBILITA'' LIQ.', 'Attivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 7, 33000, 'C/C.BANCARI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 7, 34100, 'CASSA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 7, 34105, 'CASSA - ASSEGNI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (8, 350, 'RATEI E RISCONTI ATTIVI', 'Attivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 8, 35000, 'RATEI ATTIVI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 8, 35200, 'RISCONTI ATTIVI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (9, 360, 'PATRIMONIO', 'Passivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 9, 36000, 'CAPITALE SOCIALE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 9, 36100, 'RISERVA LEGALE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 9, 36950, 'UTILE D''ESERCIZIO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 9, 36970, 'PERDITA D''ESERCIZIO')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (10, 453, 'DEBITI VS.ALTRI FINANZIATORI', 'Passivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 10, 45310, 'FINANZIAMENTO SOCI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 10, 45311, 'SOCI C/VERSAMENTO INFRUTTIFERO')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (11, 495, 'DEBITI TRIBUTARI', 'Passivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49505, 'ERARIO C/RIT.FISC.1001 DIP.TE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49507, 'ERARIO C/RIT. FISC. 1040')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49508, 'ERARIO C/RIT. FISC. 1012')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49510, 'DEBITI TRIBUTARI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49514, 'ERARIO C/RIT. FISC. 1038')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49519, 'RIT. INPS SU COMPENSI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49525, 'RIT.ADDIZ.COMUNALE IRPEF')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49527, 'RIT.IRPEF PER COMPENSI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49529, 'RITENUTA INAIL')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49600, 'DEBITI VS.INPS')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49603, 'DEBITI VS. INAIL')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 11, 49630, 'DEBITI C/LIQUIDAZIONI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (12, 498, 'ALTRI DEBITI', 'Passivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49800, 'DEBITI PER SALARI E STIPENDI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49803, 'DEBITI VARI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49804, 'FATTURE DA RICEVERE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49850, 'CLIENTI C/ANTICIPI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49851, 'CREDITORI DIVERSI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49855, 'SOCI C/VERSAMENTO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 12, 49861, 'DEBITI PER COMPENSI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (13, 500, 'RATEI E RISCONTI PASSIVI', 'Passivo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 13, 50000, 'RATEI PASSIVI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 13, 50100, 'RISCONTI PASSIVI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (14, 515, 'MERCI C/VENDITA - PRESTAZIONI', 'Ricavo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 51600, 'MERCI C/VENDITE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 51601, 'FATTURAZIONI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 56042, 'SOMMINISTRAZIONE ALIM.BEVANDE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 51618, 'PRESTAZIONI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 51619, 'FATTURAZIONI A CONDOMINI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 52120, 'RIMANENZE FINALI MERCI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 52201, 'RIMANENZE MATERIALE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 14, 52403, 'RIMBORSO SPESE DA CLIENTI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (15, 541, 'MERCI C/ACQUISTI', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54100, 'MERCI C/ACQUISTI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54103, 'LAVORI DI TERZI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54111, 'MATERIALI C/ACQUISTI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54131, 'LAVORI DI TERZI E MERCI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54140, 'IMBALLAGGI C/ACQUISTI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54141, 'CANCELLERIA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54142, 'CARBURANTI E LUBRIFICANTI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54143, 'MATERIALE DI PULIZIE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54144, 'MATER. ACCESS. VENDITA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54150, 'SCONTI ABBUONI RIBASSI PASSIVI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 15, 54154, 'CARB. E LUBRIF. USO PROM.')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (16, 550, 'COSTI PER SERVIZI', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55005, 'PRESTAZIONI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55008, 'SPESE COMMISSIONI BANCARIE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55009, 'SPESE INCASSO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55010, 'FORZA MOTRICE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55011, 'SPESE CONDOMINIALI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55014, 'MANUTENZIONE E RIPARAZIONE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55016, 'CANONI DI ASSISTENZA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55017, 'SPESE ASSICURAZIONI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55018, 'SPESE PUBBLICITA''')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55019, 'TRASPORTI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55020, 'POSTALI E TELEGRAFICHE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55021, 'SPESE TELEFONICHE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55024, 'PARCHEGGIO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55025, 'PRESTAZIONI PROFESSIONALI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55028, 'CONSULENZA SOFTWARE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55035, 'SPESE ISTRUTTORIE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55036, 'SPESE VIGILANZA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55037, 'LAVORI DI PULIZIA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55042, 'SPESE ALLESTIMENTO VETRINA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55049, 'OMAGGI E REGALIE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55058, 'SPESE ANTICIPATE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55059, 'SPESE PER RECUPERO CREDITI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55099, 'SPESE LEGALI NOTARILI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55141, 'ABITI DA LAVORO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55143, 'AGGIORNAMENTI PROGR. COMPUTER')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55144, 'AGGIORNAMENTI PROFESSIONALI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55145, 'VIAGGI E TRASFERTE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55548, 'ACQUA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55550, 'GESTIONE AUTOMEZZI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55553, 'GESTIONE AUTOM.USO PROMISCUO')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55555, 'RAPPRESENTANZA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55556, 'SMALTIMENTO RIFIUTI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55562, 'COLLABORAZIONI OCCASIONALI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 16, 55572, 'SPESE ALBERGHI E RISTORANTI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (17, 560, 'COSTI PER IL GODIMENTO DI BENI', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 17, 56000, 'NOLEGGI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 17, 56001, 'NOLEGGIO MACCHINARI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 17, 56002, 'AFFITTI PASSIVI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 17, 56005, 'CANONE LEASING 100%')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 17, 56011, 'NOLEGGIO AUTO')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (18, 561, 'COSTI PERSONALE', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 18, 56100, 'SALARI E STIPENDI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 18, 56102, 'DIARIE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 18, 56104, 'INDENNITA'' FINE RAPPORTO')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (19, 562, 'ONERI CONTRIBUTIVI', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 19, 56200, 'CONTRIBUTI INPS')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 19, 56201, 'CONTRIBUTI INAIL')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 19, 56208, 'C.A.P. 2%')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 19, 56212, 'CONTRIBUTI INPS PER COLLABOR.')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (20, 563, 'ALTRI COSTI', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 20, 56308, 'BENI STRUMENTALI < 516,46')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 20, 56309, 'COSTI NON DI COMP.DELL''ESERC.')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 20, 56339, 'GAS')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (21, 565, 'AMMORTAMENTI E SVALUTAZ.IMMOB.', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 21, 56501, 'AMM. ORDINARI BENI MATERIALI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 21, 56501, 'AMM. ORDINARI BENI IMMATERIALI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (22, 567, 'ESISTENZE INIZIALI', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 22, 56701, 'ESISTENZE INIZ. MERCI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 22, 56703, 'ESIS.INIZ.PROD.IN CORSO DI LAV')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 22, 56708, 'ESISTENZE INIZ. MATERIALE')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (23, 568, 'ACCANTONAMENTO PER RISCHI', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 23, 56801, 'FONDO IMPOSTE E TASSE')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (24, 569, 'ALTRI ACCANTONAMENTI', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 24, 56900, 'ACC.TO INDENNITA'' ANZIANITA''')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 24, 56903, 'ACC.TO INDENNITA'' FINE MANDATO')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (25, 570, 'ONERI DIVERSI DI GESTIONE', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57003, 'SPESE VARIE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57006, 'SPESE ALLESTIMENTO VETRINE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57007, 'SERVIZI VARI LEGGE 626')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57010, 'ELABORAZIONE DATI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57011, 'ABBONAMENTI RIVISTE E GIORNALI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57012, 'SPESE DI PULIZIE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57017, 'SPESE DOCUMENTATE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57018, 'EROGAZIONI LIBERALI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 57029, 'I.M.U.')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 63000, 'COMPENSI A PROFESSIONISTI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 63001, 'COMPENSI AMMINISTRATORI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 63004, 'COMPENSI PER COLLABORAZIONE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 63020, 'VALORI BOLLATI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 63030, 'SPESE BOLLI E TRATTE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 64000, 'IMPOSTE E TASSE DEDUCIBILI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 64001, 'DIRITTI CAMERALI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 64020, 'IMPOSTE E TASSE INDEDUCIBILI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 64056, 'COSTI NON DEDUCIBILI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 64062, 'SANZIONE PECUNIARIA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 65004, 'RICAVI NON DI COMPETENZA')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 25, 65012, 'ARROTONDAMENTI ATTIVI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (26, 650, 'PROVENTI DA PARTECIPAZIONI', 'Ricavo')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (27, 654, 'ALTRI PROVENTI FINANZIARI', 'Ricavo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 27, 65400, 'INTER.ATTIVI C/C BANCARI E PT')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (28, 700, 'ONERI FINANZIARI E BANCARI', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 28, 70005, 'ARROTONDAMENTI PASSIVI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 28, 70500, 'SPESE E ONERI BANCARI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 28, 70501, 'INTER.PASSIVI C/C BANCARI E PT')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 28, 70503, 'INTERESSI PASSIVI FINANZIARI')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 28, 70504, 'INTER.PASS.SU DEBITI DIVERSI')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (29, 750, 'PROVENTI STRAORDINARI', 'Ricavo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 29, 75001, 'SOPRAVVENIENZE ATTIVE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 29, 75002, 'PLUSVAL. ALIENAZIONE')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (30, 800, 'ONERI STRAORDINARI', 'Costo')")

    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 30, 80001, 'SOPRAVVENIENZE PASSIVE')")
    execute("insert into pdc (id, categoria_pdc_id, codice, descrizione) values (NULL, 30, 82507, 'ACCANTONAMENTO IRAP')")

    execute("insert into categorie_pdc (id, codice, descrizione, type) values (31, 220, 'CLIENTI', 'Attivo')")
    execute("insert into categorie_pdc (id, codice, descrizione, type) values (32, 460, 'FORNITORI', 'Passivo')")

    # norma
    execute("insert into norma (id, codice, percentuale, descrizione) values (NULL, 20, 20, 'Acq. con Iva Indetraibile 20%')")
    execute("insert into norma (id, codice, percentuale, descrizione) values (NULL, 40, 40, 'Acq. con Iva Indetraibile 40%')")
    execute("insert into norma (id, codice, percentuale, descrizione) values (NULL, 50, 50, 'Acq. con Iva Indetraibile 50%')")
    execute("insert into norma (id, codice, percentuale, descrizione) values (NULL, 80, 80, 'Acq. con Iva Indetraibile 80%')")
    execute("insert into norma (id, codice, percentuale, descrizione) values (NULL, 100, 100, 'Acq. con Iva Indetraibile 100%')")

  end

  def self.down

  end
end
