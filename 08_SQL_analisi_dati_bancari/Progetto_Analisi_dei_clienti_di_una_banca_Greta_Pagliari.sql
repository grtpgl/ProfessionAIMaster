/*
ANALISI DEI CLIENTI DI UNA BANCA

Descrizione del Progetto
L'azienda Banking Intelligence vuole sviluppare un modello di machine learning supervisionato per prevedere i comportamenti futuri dei propri clienti, basandosi sui dati transazionali e sulle caratteristiche del possesso di prodotti. Lo scopo del progetto è creare una tabella denormalizzata con una serie di indicatori (feature) derivati dalle tabelle disponibili nel database, che rappresentano i comportamenti e le attività finanziarie dei clienti.

Obiettivo
Il nostro obiettivo è creare una tabella di feature per il training di modelli di machine learning, arricchendo i dati dei clienti con vari indicatori calcolati a partire dalle loro transazioni e dai conti posseduti. La tabella finale sarà riferita all'ID cliente e conterrà informazioni sia di tipo quantitativo che qualitativo.

Valore Aggiunto
La tabella denormalizzata permetterà di estrarre feature comportamentali avanzate per l'addestramento di modelli di machine learning supervisionato, fornendo numerosi vantaggi per l'azienda:
1 - Predizione del comportamento dei clienti: Analizzando le transazioni e il possesso di prodotti, si possono identificare pattern di comportamento utili per prevedere azioni future come l'acquisto di nuovi prodotti o la chiusura di conti.
2 - Riduzione del tasso di abbandono: Utilizzando gli indicatori comportamentali, si può costruire un modello per identificare i clienti a rischio di abbandono, permettendo interventi tempestivi da parte del team di marketing.
3 - Miglioramento della gestione del rischio: La segmentazione basata su comportamenti finanziari consente di individuare clienti ad alto rischio e ottimizzare le strategie di credito e rischio.
4 - Personalizzazione delle offerte: Le feature estratte possono essere utilizzate per personalizzare offerte di prodotti e servizi in base alle abitudini e preferenze dei singoli clienti, aumentando così la customer satisfaction.
5 - Prevenzione delle frodi: Attraverso l’analisi delle transazioni per tipologia e importi, il modello può rilevare anomalie comportamentali indicative di frodi, migliorando le strategie di sicurezza e prevenzione.
Questi vantaggi porteranno un miglioramento complessivo delle operazioni aziendali, consentendo una maggiore efficienza nella gestione dei clienti e una crescita sostenibile del business.

*/


/*
CALCOLO DEGLI INDICATORI COMPORTAMENTALI
1- Indicatori di base
Età del cliente (da tabella cliente).

2 - Indicatori sulle transazioni
Numero di transazioni in uscita su tutti i conti.
Numero di transazioni in entrata su tutti i conti.
Importo totale transato in uscita su tutti i conti.
Importo totale transato in entrata su tutti i conti.

3 - Indicatori sui conti
Numero totale di conti posseduti.
Numero di conti posseduti per tipologia (un indicatore per ogni tipo di conto).

4 - Indicatori sulle transazioni per tipologia di conto
Numero di transazioni in uscita per tipologia di conto (un indicatore per tipo di conto).
Numero di transazioni in entrata per tipologia di conto (un indicatore per tipo di conto).
Importo transato in uscita per tipologia di conto (un indicatore per tipo di conto).
Importo transato in entrata per tipologia di conto (un indicatore per tipo di conto).

NOTA. Per ognuna delle 4 tipologie di indicatori viene creata una TABELLA TEMPORANEA (= Temporary table), 
che serve per trasformazioni e calcoli intermedi.
*/


# INDICATORE: età del cliente

select
	nome, cognome,
    TIMESTAMPDIFF(YEAR, data_nascita, current_date()) AS eta
from banca.cliente;


# --> NUOVA TABELLA TEMPORANEA: feature_cliente

CREATE TEMPORARY TABLE banca.feature_cliente AS
SELECT
	id_cliente,
    TIMESTAMPDIFF(YEAR, data_nascita, current_date()) AS eta
FROM banca.cliente;

-- ---------------------------------------------------------------------------------------------------

# INDICATORE: Numero di transazioni in uscita su tutti i conti.
	# join tra le tabelle 'transazioni' e 'tipo_transazione' per associare a ogni transazione il segno
    # Filtro delle transazioni in uscita (segno negativo)
    # Conteggio delle transazioni

SELECT 
    c.id_cliente,
    COUNT(CASE WHEN tt.segno = '-' THEN 1 END) AS numero_transazioni_uscita
FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.transazioni t
    ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt
    ON t.id_tipo_trans = tt.id_tipo_transazione
GROUP BY 1;


# INDICATORE: Numero di transazioni in ENTRATA su tutti i conti.

SELECT 
    c.id_cliente,
    COUNT(CASE WHEN tt.segno = '+' THEN 1 END) AS numero_transazioni_entrata
FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.transazioni t
    ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt
    ON t.id_tipo_trans = tt.id_tipo_transazione
GROUP BY 1;


# INDICATORE: Importo totale transato in uscita su tutti i conti.

SELECT 
    c.id_cliente,
    SUM(CASE WHEN tt.segno = '-' THEN t.importo ELSE 0 END) AS totale_transazioni_uscita
FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.transazioni t
    ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt
    ON t.id_tipo_trans = tt.id_tipo_transazione
GROUP BY 1;


# INDICATORE: Importo totale transato in entrata su tutti i conti.

SELECT 
    c.id_cliente,
    SUM(CASE WHEN tt.segno = '+' THEN t.importo ELSE 0 END) AS totale_transazioni_entrata
FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.transazioni t
    ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt
    ON t.id_tipo_trans = tt.id_tipo_transazione
GROUP BY 1;



# --> NUOVA TABELLA TEMPORANEA feature_transazioni

CREATE TEMPORARY TABLE banca.feature_transazioni AS
SELECT
	c.id_cliente,
    
    # Numero transazioni in uscita:
    COUNT(CASE WHEN tt.segno = '-' THEN 1 END) AS numero_transazioni_uscita,
    # Numero transazioni in entrata:
    COUNT(CASE WHEN tt.segno = '+' THEN 1 END) AS numero_transazioni_entrata,
    
    # Importo totale transato in uscita
    SUM(CASE WHEN tt.segno = '-' THEN t.importo ELSE 0 END) AS totale_transazioni_uscita,
    # Importo totale transato in entrata
    SUM(CASE WHEN tt.segno = '+' THEN t.importo ELSE 0 END) AS totale_transazioni_entrata
    
FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.transazioni t
    ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt
    ON t.id_tipo_trans = tt.id_tipo_transazione
GROUP BY 1;


# visualizzazione della tabella
select * from banca.feature_transazioni;


-- ---------------------------------------------------------------------------------------------------

# INDICATORE: Numero totale di conti posseduti.

SELECT 
    c.id_cliente,
    COUNT(DISTINCT id_conto) AS numero_totale_conti
FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
GROUP BY 1;


# INDICATORE: Numero di conti posseduti per tipologia (un indicatore per ogni tipo di conto).
	# Step 1: join conto + tipo_conto
    # Step 2: aggregazione per cliente + tipo
    # Step 3: CASE WHEN

SELECT 
    c.id_cliente,
    COUNT(CASE WHEN tc.desc_tipo_conto = 'Conto Base' THEN 1 END) AS conto_base,
    COUNT(CASE WHEN tc.desc_tipo_conto = 'Conto Business' THEN 1 END) AS conto_business,
    COUNT(CASE WHEN tc.desc_tipo_conto = 'Conto Privati' THEN 1 END) AS conto_privati,
    COUNT(CASE WHEN tc.desc_tipo_conto = 'Conto Famiglie' THEN 1 END) AS conto_famiglie
FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.tipo_conto tc
    ON co.id_tipo_conto = tc.id_tipo_conto
GROUP BY 1;


# --> NUOVA TABELLA TEMPORANEA feature_conti

CREATE TEMPORARY TABLE banca.feature_conti AS
 
SELECT 
	c.id_cliente, 
    # Numero totale di conti posseduti:
    COUNT(DISTINCT co.id_conto) AS numero_totale_conti,
    # Numero di conti posseduti PER TIPOLOGIA
    COUNT(CASE WHEN tc.desc_tipo_conto = 'Conto Base' THEN 1 END) AS conto_base,
    COUNT(CASE WHEN tc.desc_tipo_conto = 'Conto Business' THEN 1 END) AS conto_business,
    COUNT(CASE WHEN tc.desc_tipo_conto = 'Conto Privati' THEN 1 END) AS conto_privati,
    COUNT(CASE WHEN tc.desc_tipo_conto = 'Conto Famiglie' THEN 1 END) AS conto_famiglie

FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.tipo_conto tc
    ON co.id_tipo_conto = tc.id_tipo_conto
GROUP BY 1;


# visualizzazione della tabella
select * from banca.feature_conti;

-- -------------------------------------------------------------------------------------------------


# INDICATORE: Numero di transazioni in uscita per tipologia di conto (un indicatore per tipo di conto).
# 1. join tra tabella conto e tabella transazioni: collega ogni conto alle sue transazioni
# 2. join tra tabella transazioni e tabella tipo_transazione: collega ogni transazione alla tipologia
# 3. conteggio di tutte le transazioni in uscita per tipo
# 4. group by divide i dati per cliente

SELECT
    c.id_cliente,
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Base' THEN 1 END) AS trans_uscita_conto_base,
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Business' THEN 1 END) AS trans_uscita_conto_business,
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Privati' THEN 1 END) AS trans_uscita_conto_privati,
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Famiglie' THEN 1 END) AS trans_uscita_conto_famiglie

FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.tipo_conto tc
    ON co.id_tipo_conto = tc.id_tipo_conto
LEFT JOIN banca.transazioni t
    ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt
    ON t.id_tipo_trans = tt.id_tipo_transazione
GROUP BY 1;


# INDICATORE: Numero di transazioni in entrata per tipologia di conto (un indicatore per tipo di conto).

SELECT
    c.id_cliente,
    COUNT(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Base' THEN 1 END) AS trans_entrata_conto_base,
    COUNT(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Business' THEN 1 END) AS trans_entrata_conto_business,
    COUNT(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Privati' THEN 1 END) AS trans_entrata_conto_privati,
    COUNT(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Famiglie' THEN 1 END) AS trans_entrata_conto_famiglie

FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.tipo_conto tc
    ON co.id_tipo_conto = tc.id_tipo_conto
LEFT JOIN banca.transazioni t
    ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt
    ON t.id_tipo_trans = tt.id_tipo_transazione
GROUP BY 1;



# INDICATORE: Importo transato in uscita per tipologia di conto (un indicatore per tipo di conto).

SELECT
    c.id_cliente,

    SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Base' THEN t.importo ELSE 0 END) AS importo_uscita_conto_base,
    SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Business' THEN t.importo ELSE 0 END) AS importo_uscita_conto_business,
    SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Privati' THEN t.importo ELSE 0 END) AS importo_uscita_conto_privati,
    SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Famiglie' THEN t.importo ELSE 0 END) AS importo_uscita_conto_famiglie
    
FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.tipo_conto tc
    ON co.id_tipo_conto = tc.id_tipo_conto
LEFT JOIN banca.transazioni t
    ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt
    ON t.id_tipo_trans = tt.id_tipo_transazione
GROUP BY 1;


# INDICATORE: Importo transato in entrata per tipologia di conto (un indicatore per tipo di conto).

SELECT
    c.id_cliente,

    SUM(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Base' THEN t.importo ELSE 0 END) AS importo_entrata_conto_base,
    SUM(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Business' THEN t.importo ELSE 0 END) AS importo_entrata_conto_business,
    SUM(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Privati' THEN t.importo ELSE 0 END) AS importo_entrata_conto_privati,
    SUM(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Famiglie' THEN t.importo ELSE 0 END) AS importo_entrata_conto_famiglie
    
FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.tipo_conto tc
    ON co.id_tipo_conto = tc.id_tipo_conto
LEFT JOIN banca.transazioni t
    ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt
    ON t.id_tipo_trans = tt.id_tipo_transazione
GROUP BY 1;



# --> NUOVA TABELLA TEMPORANEA feature_transazioni_per_conto

CREATE TEMPORARY TABLE banca.feature_transazioni_per_conto AS
SELECT
    c.id_cliente,

    /* Numero transazioni in uscita */
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Base' THEN 1 END) AS trans_uscita_conto_base,
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Business' THEN 1 END) AS trans_uscita_conto_business,
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Privati' THEN 1 END) AS trans_uscita_conto_privati,
    COUNT(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Famiglie' THEN 1 END) AS trans_uscita_conto_famiglie,

    /* Numero transazioni in entrata */
    COUNT(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Base' THEN 1 END) AS trans_entrata_conto_base,
    COUNT(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Business' THEN 1 END) AS trans_entrata_conto_business,
    COUNT(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Privati' THEN 1 END) AS trans_entrata_conto_privati,
    COUNT(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Famiglie' THEN 1 END) AS trans_entrata_conto_famiglie,

    /* Importi transati in uscita */
    SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Base' THEN t.importo ELSE 0 END) AS importo_uscita_conto_base,
    SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Business' THEN t.importo ELSE 0 END) AS importo_uscita_conto_business,
    SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Privati' THEN t.importo ELSE 0 END) AS importo_uscita_conto_privati,
    SUM(CASE WHEN tt.segno = '-' AND tc.desc_tipo_conto = 'Conto Famiglie' THEN t.importo ELSE 0 END) AS importo_uscita_conto_famiglie,

    /* Importi transati in entrata */
    SUM(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Base' THEN t.importo ELSE 0 END) AS importo_entrata_conto_base,
    SUM(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Business' THEN t.importo ELSE 0 END) AS importo_entrata_conto_business,
    SUM(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Privati' THEN t.importo ELSE 0 END) AS importo_entrata_conto_privati,
    SUM(CASE WHEN tt.segno = '+' AND tc.desc_tipo_conto = 'Conto Famiglie' THEN t.importo ELSE 0 END) AS importo_entrata_conto_famiglie

FROM banca.cliente c
LEFT JOIN banca.conto co
    ON c.id_cliente = co.id_cliente
LEFT JOIN banca.tipo_conto tc
    ON co.id_tipo_conto = tc.id_tipo_conto
LEFT JOIN banca.transazioni t
    ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt
    ON t.id_tipo_trans = tt.id_tipo_transazione
GROUP BY 1;


# visualizzazione della tabella
select * from banca.feature_transazioni_per_conto;


-- -------------------------------------------------------------------------------------------------


/*
CREAZIONE DELLA TABELLA DENORMALIZZATA

La tabella finale è riferita all'ID cliente, quindi ogni riga deve rappresentare un singolo cliente, 
con tutte le sue caratteristiche raccolte in un'unica struttura.
Questa tabella di feature è indicata per il training di modelli di Machine Learning supervisionato
(come Logistic Regression, Random Forest, XGBoost ...), che possono essere usati per prevedere i comportamenti 
futuri dei propri clienti, basandosi sui dati transazionali e sulle caratteristiche del possesso di prodotti. 

NOTA. La tabella finale non è stata creata come tabella temporanea, ma come TABELLA PERSISTENTE, perchè è pensata 
per essere conservata a scopo documentativo, esportata, utilizzata (e riutilizzata) nel training del modello di machine Learning.

NOTA. Si usa COALESCE per sostituire i valori NULL con un valore a scelta (in questo caso: zero).
*/


CREATE TABLE banca.tabella_finale AS
SELECT
    fc.id_cliente,
    fc.eta,

    -- Feature conti
    COALESCE(fco.numero_totale_conti, 0) AS numero_totale_conti,
    COALESCE(fco.conto_base, 0) AS conto_base,
    COALESCE(fco.conto_business, 0) AS conto_business,
    COALESCE(fco.conto_privati, 0) AS conto_privati,
    COALESCE(fco.conto_famiglie, 0) AS conto_famiglie,

    -- Feature transazioni complessive
    COALESCE(ft.numero_transazioni_uscita, 0) AS numero_transazioni_uscita,
    COALESCE(ft.numero_transazioni_entrata, 0) AS numero_transazioni_entrata,
    COALESCE(ft.totale_transazioni_uscita, 0) AS totale_transazioni_uscita,
    COALESCE(ft.totale_transazioni_entrata, 0) AS totale_transazioni_entrata,

    -- Feature transazioni per tipologia conto
    COALESCE(ftp.trans_uscita_conto_base, 0) AS trans_uscita_conto_base,
    COALESCE(ftp.trans_uscita_conto_business, 0) AS trans_uscita_conto_business,
    COALESCE(ftp.trans_uscita_conto_privati, 0) AS trans_uscita_conto_privati,
    COALESCE(ftp.trans_uscita_conto_famiglie, 0) AS trans_uscita_conto_famiglie,

    COALESCE(ftp.trans_entrata_conto_base, 0) AS trans_entrata_conto_base,
    COALESCE(ftp.trans_entrata_conto_business, 0) AS trans_entrata_conto_business,
    COALESCE(ftp.trans_entrata_conto_privati, 0) AS trans_entrata_conto_privati,
    COALESCE(ftp.trans_entrata_conto_famiglie, 0) AS trans_entrata_conto_famiglie,

    COALESCE(ftp.importo_uscita_conto_base, 0) AS importo_uscita_conto_base,
    COALESCE(ftp.importo_uscita_conto_business, 0) AS importo_uscita_conto_business,
    COALESCE(ftp.importo_uscita_conto_privati, 0) AS importo_uscita_conto_privati,
    COALESCE(ftp.importo_uscita_conto_famiglie, 0) AS importo_uscita_conto_famiglie,

    COALESCE(ftp.importo_entrata_conto_base, 0) AS importo_entrata_conto_base,
    COALESCE(ftp.importo_entrata_conto_business, 0) AS importo_entrata_conto_business,
    COALESCE(ftp.importo_entrata_conto_privati, 0) AS importo_entrata_conto_privati,
    COALESCE(ftp.importo_entrata_conto_famiglie, 0) AS importo_entrata_conto_famiglie


FROM banca.feature_cliente fc
LEFT JOIN banca.feature_conti fco
    ON fc.id_cliente = fco.id_cliente
LEFT JOIN banca.feature_transazioni ft
    ON fc.id_cliente = ft.id_cliente
LEFT JOIN banca.feature_transazioni_per_conto ftp
    ON fc.id_cliente = ftp.id_cliente;


SELECT * 
FROM banca.tabella_finale
LIMIT 10;


-- -------------------------------------------------------------------------------------------------

# Controllo che non ci siano valori NULL nella tabella finale

SELECT 
    SUM(CASE WHEN id_cliente IS NULL THEN 1 ELSE 0 END) AS null_id_cliente,
    SUM(CASE WHEN eta IS NULL THEN 1 ELSE 0 END) AS null_eta,
    SUM(CASE WHEN numero_totale_conti IS NULL THEN 1 ELSE 0 END) AS null_conti,
    SUM(CASE WHEN numero_transazioni_uscita IS NULL THEN 1 ELSE 0 END) AS null_uscite,
    SUM(CASE WHEN numero_transazioni_entrata IS NULL THEN 1 ELSE 0 END) AS null_entrate,
    SUM(CASE WHEN totale_transazioni_uscita IS NULL THEN 1 ELSE 0 END) AS null_importo_uscite,
    SUM(CASE WHEN totale_transazioni_entrata IS NULL THEN 1 ELSE 0 END) AS null_importo_entrate
FROM banca.tabella_finale;


-- -------------------------------------------------------------------------------------------------
/* Eliminazione delle tabelle, per poter rieseguire il codice modificato.
DROP TABLE IF EXISTS banca.tabella_finale;
DROP TEMPORARY TABLE IF EXISTS banca.feature_cliente;
DROP TEMPORARY TABLE IF EXISTS banca.feature_conti;
DROP TEMPORARY TABLE IF EXISTS banca.feature_transazioni;
DROP TEMPORARY TABLE IF EXISTS banca.feature_transazioni_per_conto;
*/
-- -------------------------------------------------------------------------------------------------