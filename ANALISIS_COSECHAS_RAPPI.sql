-- ============================ --
-- RAPPI RETENTION PROJECT   == --
-- 11/06/2022                == --
-- CREADO POR: CHARLY MORENO == --
-- ============================ --

USE Retention_Rappi
GO

;


-- 1. CREANDO TABLA A NIVEL DE CLIENTE POR DIA PARA NEW USERS (COSECHAS) (5MIN) // SOLO REGISTROS DE NEW ORDER

SELECT  APPLICATION_USER_ID AS CUSTOMER_ID
	   , MONTH(IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT)) AS MES_COSECHA
	   , YEAR(IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT)) AS YEAR_COSECHA

	   -- CRTS DE ORDENES = ORD
	   , SUM(IIF(ORDER_STATE IS NOT NULL,1,0)) AS ORD_ORDENES_TOTALES
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review'), 1, 0)) AS ORD_ORDENES_COMPLETADAS
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND (
			IIF(DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT),  IIF(ETA = '1753-01-01 00:00:00.000', NULL, ETA))=0, NULL, (DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), IIF(RT_ARRIVE_AT='1753-01-01 00:00:00.000', NULL, RT_ARRIVE_AT))*1.0000/ DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), ETA)))
			) <=1.0, 1,0)) AS ORD_ORDENES_COMPLETADAS_A_TIEMPO
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND (
			IIF(DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT),  IIF(ETA = '1753-01-01 00:00:00.000', NULL, ETA))=0, NULL, (DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), IIF(RT_ARRIVE_AT='1753-01-01 00:00:00.000', NULL, RT_ARRIVE_AT))*1.0000/ DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), ETA)))
			) >1.0, 1,0)) AS ORD_ORDENES_COMPLETADAS_CON_RETRASO
	   , SUM(IIF(ORDER_STATE IN ('canceled','canceled_with_charge', 'canceled_by_automation', 'canceled_by_fraud'), 1, 0)) AS ORD_ORDENES_CANCELADAS
	   , SUM(IIF(ORDER_STATE NOT IN ('finished','pending_review','canceled','canceled_with_charge', 'canceled_by_automation', 'canceled_by_fraud'), 1, 0)) AS ORD_ORDENES_OTROS

	   -- CRTS DE MONTOS = MNT (SOLO ORDENES COMPLETADAS)
	   ,  SUM(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(GMV AS NUMERIC(20,6))*1.0000,NULL)) AS MNT_TOTAL_GMV
	   ,  SUM(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(TOTAL_DISCOUNT AS NUMERIC(20,6))*1.0000,NULL)) AS MNT_TOTAL_DESCUENTO
  	   ,  SUM(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(SHIPPING AS NUMERIC(20,6))*1.0000,NULL)) AS MNT_TOTAL_COSTO_ENVIO
	   ,  SUM(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(SERVICE_COST AS NUMERIC(20,6))*1.0000,NULL)) AS MNT_TOTAL_COSTO_SERVICIO
	   ,  SUM(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(TIP AS NUMERIC(20,6))*1.0000,NULL)) AS MNT_TOTAL_PROPINA

	   ,  AVG(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(GMV AS NUMERIC(20,6))*1.0000,NULL)) AS MNT_PROM_GMV
	   ,  AVG(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(TOTAL_DISCOUNT AS NUMERIC(20,6))*1.0000,NULL)) AS MNT_PROM_DESCUENTO
  	   ,  AVG(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(SHIPPING AS NUMERIC(20,6))*1.0000,NULL)) AS MNT_PROM_COSTO_ENVIO
	   ,  AVG(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(SERVICE_COST AS NUMERIC(20,6))*1.0000,NULL)) AS MNT_PROM_PROM_SERVICIO
	   ,  AVG(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(TIP AS NUMERIC(20,6))*1.0000,NULL)) AS MNT_PROM_PROPINA

	  -- CRTS DE MEDIOS DE PAGO = MDP
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('cash'), 1,0)) AS MDP_TOT_ORDENES_CASH
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('cc'), 1,0)) AS MDP_TOT_ORDENES_TDC
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('nequi', 'pse_avanza', 'pse'), 1,0)) AS MDP_TOT_ORDENES_PAGO_DIGITAL
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('rappi_pay', 'rappi_pay_gateway', 'rappi_credits', 'rappi_pay_gateway_wallet'), 1,0)) AS MDP_TOT_ORDENES_PAGO_DIGITAL_RAPPI
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('cc') AND CARD_BRAND IN ('DEBIT'),1,0)) AS MDP_TOT_TARJETA_DEBITO 
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('cc') AND CARD_BRAND IN ('LOCAL BRAND', 'SERFINANZA'),1,0)) AS MDP_TOT_TDC_NACIONAL
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('cc') AND CARD_BRAND IN ('VISA', 'master', 'MASTERCARD', 'AMERICAN EXPRESS', 'DINERS CLUB INTERNATIONAL', 'DISCOVER'),1,0)) AS MDP_TOT_TDC_INTERNACIONAL

	  -- CRTS DE CX = EXP
	   , AVG(DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), IIF(RT_ARRIVE_AT='1753-01-01 00:00:00.000', NULL, RT_ARRIVE_AT))) AS EXP_TIEMPO_ESPERA_EFECTIVO_M
	   , AVG(DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT),  IIF(ETA = '1753-01-01 00:00:00.000', NULL, ETA))) AS EXP_TIEMPO_ESPERA_PROMETIDO_M
	   , AVG(IIF(DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT),  IIF(ETA = '1753-01-01 00:00:00.000', NULL, ETA))=0, NULL, (DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), IIF(RT_ARRIVE_AT='1753-01-01 00:00:00.000', NULL, RT_ARRIVE_AT))*1.0000/ DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), ETA)))) AS EXP_KPI_TIEMPO_ESPERA
	   , SUM(IIF([TYPE] = 'Non-defect',0,1)) AS EXP_ORDEN_CON_RECLAMO, SUM(IIF([TYPE] = 'Non-defect',1,0)) AS EXP_ORDEN_SIN_RECLAMO
	   , SUM(IIF(OS='WEB',1,0)) AS EXP_ORDENES_WEB, SUM(IIF(OS='ANDROID',1,0)) AS EXP_ORDENES_ANDROID, SUM(IIF(OS='IOS',1,0)) AS EXP_ORDENES_IOS

INTO Retention_Rappi..COSECHAS
FROM [Data_Retention_Rappi]
WHERE USER_TYPE_ORDER = 'FIRST ORDER'
GROUP BY APPLICATION_USER_ID, MONTH(IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT)) 
	   , YEAR(IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT))

;


-- 2. CREANDO TABLA A NIVEL DE CLIENTE POR DIA PARA TODAS LAS ORDENES (HECHOS) (5MIN) // TODOS LOS REGISTROS

SELECT  APPLICATION_USER_ID AS CUSTOMER_ID
	   , MONTH(IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT)) AS MES_CLIENTE
	   , YEAR(IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT)) AS YEAR_CLIENTE

	   -- CRTS DE ORDENES = ORD
	   , SUM(IIF(ORDER_STATE IS NOT NULL,1,0)) AS ORD_ORDENES_TOTALES
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review'), 1, 0)) AS ORD_ORDENES_COMPLETADAS
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND (
			IIF(DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT),  IIF(ETA = '1753-01-01 00:00:00.000', NULL, ETA))=0, NULL, (DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), IIF(RT_ARRIVE_AT='1753-01-01 00:00:00.000', NULL, RT_ARRIVE_AT))*1.0000/ DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), ETA)))
			) <=1.0, 1,0)) AS ORD_ORDENES_COMPLETADAS_A_TIEMPO
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND (
			IIF(DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT),  IIF(ETA = '1753-01-01 00:00:00.000', NULL, ETA))=0, NULL, (DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), IIF(RT_ARRIVE_AT='1753-01-01 00:00:00.000', NULL, RT_ARRIVE_AT))*1.0000/ DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), ETA)))
			) >1.0, 1,0)) AS ORD_ORDENES_COMPLETADAS_CON_RETRASO
	   , SUM(IIF(ORDER_STATE IN ('canceled','canceled_with_charge', 'canceled_by_automation', 'canceled_by_fraud'), 1, 0)) AS ORD_ORDENES_CANCELADAS
	   , SUM(IIF(ORDER_STATE NOT IN ('finished','pending_review','canceled','canceled_with_charge', 'canceled_by_automation', 'canceled_by_fraud'), 1, 0)) AS ORD_ORDENES_OTROS

	   -- CRTS DE MONTOS = MNT (SOLO ORDENES COMPLETADAS)
	   ,  SUM(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(GMV AS NUMERIC(30,10))*1.0000,NULL)) AS MNT_TOTAL_GMV
	   ,  SUM(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(TOTAL_DISCOUNT AS NUMERIC(30,10))*1.0000,NULL)) AS MNT_TOTAL_DESCUENTO
  	   ,  SUM(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(IIF(ISNUMERIC(SHIPPING)=0,NULL,SHIPPING) AS NUMERIC(30,10))*1.0000,NULL)) AS MNT_TOTAL_COSTO_ENVIO
	   ,  SUM(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(IIF(ISNUMERIC(SERVICE_COST)=0,NULL,SERVICE_COST) AS NUMERIC(30,10))*1.0000,NULL)) AS MNT_TOTAL_COSTO_SERVICIO
	   ,  SUM(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(TIP AS NUMERIC(30,10))*1.0000,NULL)) AS MNT_TOTAL_PROPINA

	   ,  AVG(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(GMV AS NUMERIC(30,10))*1.0000,NULL)) AS MNT_PROM_GMV
	   ,  AVG(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(TOTAL_DISCOUNT AS NUMERIC(30,10))*1.0000,NULL)) AS MNT_PROM_DESCUENTO
  	   ,  AVG(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(IIF(ISNUMERIC(SHIPPING)=0,NULL,SHIPPING) AS NUMERIC(30,10))*1.0000,NULL)) AS MNT_PROM_COSTO_ENVIO
	   ,  AVG(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(IIF(ISNUMERIC(SERVICE_COST)=0,NULL,SERVICE_COST) AS NUMERIC(30,10))*1.0000,NULL)) AS MNT_PROM_PROM_SERVICIO
	   ,  AVG(IIF(ORDER_STATE IN ('finished','pending_review'), CAST(TIP AS NUMERIC(30,10))*1.0000,NULL)) AS MNT_PROM_PROPINA

	  -- CRTS DE MEDIOS DE PAGO = MDP
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('cash'), 1,0)) AS MDP_TOT_ORDENES_CASH
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('cc'), 1,0)) AS MDP_TOT_ORDENES_TDC
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('nequi', 'pse_avanza', 'pse'), 1,0)) AS MDP_TOT_ORDENES_PAGO_DIGITAL
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('rappi_pay', 'rappi_pay_gateway', 'rappi_credits', 'rappi_pay_gateway_wallet'), 1,0)) AS MDP_TOT_ORDENES_PAGO_DIGITAL_RAPPI
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('cc') AND CARD_BRAND IN ('DEBIT'),1,0)) AS MDP_TOT_TARJETA_DEBITO 
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('cc') AND CARD_BRAND IN ('LOCAL BRAND', 'SERFINANZA'),1,0)) AS MDP_TOT_TDC_NACIONAL
	   , SUM(IIF(ORDER_STATE IN ('finished','pending_review') AND PAYMENT_METHOD IN ('cc') AND CARD_BRAND IN ('VISA', 'master', 'MASTERCARD', 'AMERICAN EXPRESS', 'DINERS CLUB INTERNATIONAL', 'DISCOVER'),1,0)) AS MDP_TOT_TDC_INTERNACIONAL

	  -- CRTS DE CX = EXP
	   , AVG(DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), IIF(RT_ARRIVE_AT='1753-01-01 00:00:00.000', NULL, RT_ARRIVE_AT))) AS EXP_TIEMPO_ESPERA_EFECTIVO_M
	   , AVG(DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT),  IIF(ETA = '1753-01-01 00:00:00.000', NULL, ETA))) AS EXP_TIEMPO_ESPERA_PROMETIDO_M
	   , AVG(IIF(DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT),  IIF(ETA = '1753-01-01 00:00:00.000', NULL, ETA))=0, NULL, (DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), IIF(RT_ARRIVE_AT='1753-01-01 00:00:00.000', NULL, RT_ARRIVE_AT))*1.0000/ DATEDIFF(MINUTE, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT), ETA)))) AS EXP_KPI_TIEMPO_ESPERA
	   , SUM(IIF([TYPE] = 'Non-defect',0,1)) AS EXP_ORDEN_CON_RECLAMO, SUM(IIF([TYPE] = 'Non-defect',1,0)) AS EXP_ORDEN_SIN_RECLAMO
	   , SUM(IIF(OS='WEB',1,0)) AS EXP_ORDENES_WEB, SUM(IIF(OS='ANDROID',1,0)) AS EXP_ORDENES_ANDROID, SUM(IIF(OS='IOS',1,0)) AS EXP_ORDENES_IOS

INTO Retention_Rappi..DETALLE_CLIENTES
FROM [Data_Retention_Rappi]
GROUP BY APPLICATION_USER_ID, MONTH(IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT)) 
	   , YEAR(IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT))

;


-- 3. CREANDO DATASET PARA REPORTE DE COSECHAS

SELECT  A.CUSTOMER_ID, A.MES_CLIENTE, A.YEAR_CLIENTE, B.MES_COSECHA, B.YEAR_COSECHA
	   , IIF( A.MES_CLIENTE = B.MES_COSECHA AND A.YEAR_CLIENTE = B.YEAR_COSECHA, 1, IIF(MES_COSECHA IS NULL AND YEAR_COSECHA IS NULL, NULL, 0)) AS CLTE_COSECHA 
	   , A.ORD_ORDENES_TOTALES, A.ORD_ORDENES_COMPLETADAS, A.ORD_ORDENES_COMPLETADAS_A_TIEMPO, A.ORD_ORDENES_COMPLETADAS_CON_RETRASO, A.ORD_ORDENES_CANCELADAS, A.ORD_ORDENES_OTROS
	   , A.MNT_TOTAL_GMV, A.MNT_TOTAL_DESCUENTO, A.MNT_TOTAL_COSTO_ENVIO, A.MNT_TOTAL_COSTO_SERVICIO, A.MNT_TOTAL_PROPINA, A.MNT_PROM_GMV, A.MNT_PROM_DESCUENTO, A.MNT_PROM_COSTO_ENVIO, A.MNT_PROM_PROM_SERVICIO, A.MNT_PROM_PROPINA
	   , A.MDP_TOT_ORDENES_CASH, A.MDP_TOT_ORDENES_TDC, A.MDP_TOT_ORDENES_PAGO_DIGITAL, A.MDP_TOT_ORDENES_PAGO_DIGITAL_RAPPI, A.MDP_TOT_TARJETA_DEBITO, A.MDP_TOT_TDC_NACIONAL, A.MDP_TOT_TDC_INTERNACIONAL
	   , A.EXP_TIEMPO_ESPERA_EFECTIVO_M, A.EXP_TIEMPO_ESPERA_PROMETIDO_M, A.EXP_KPI_TIEMPO_ESPERA, A.EXP_ORDEN_CON_RECLAMO, A.EXP_ORDEN_SIN_RECLAMO, A.EXP_ORDENES_WEB, A.EXP_ORDENES_ANDROID, A.EXP_ORDENES_IOS
INTO BD_COSECHAS_REPORTING
FROM DETALLE_CLIENTES AS A LEFT JOIN COSECHAS AS B ON A.CUSTOMER_ID = B.CUSTOMER_ID 

;

-- 3.1 IDENTIFICANDO CASOS RAROS // ELIMINANDO DE BD DE REPORTING

/*SELECT MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA, MES_CLIENTE, YEAR_CLIENTE, CUSTOMER_ID
INTO CASOS_RAROS_REVISAR
FROM BD_COSECHAS_REPORTING
WHERE CLTE_COSECHA = 0 AND MES_COSECHA = '1' AND YEAR_COSECHA = '2022' AND MES_CLIENTE = '12' AND YEAR_CLIENTE = '2021'
UNION ALL
SELECT MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA, MES_CLIENTE, YEAR_CLIENTE, CUSTOMER_ID
FROM BD_COSECHAS_REPORTING
WHERE CLTE_COSECHA = 0 AND MES_COSECHA = '2' AND YEAR_COSECHA = '2022' AND MES_CLIENTE = '11' AND YEAR_CLIENTE = '2021'
UNION ALL
SELECT MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA, MES_CLIENTE, YEAR_CLIENTE, CUSTOMER_ID
FROM BD_COSECHAS_REPORTING
WHERE CLTE_COSECHA = 0 AND MES_COSECHA = '10' AND YEAR_COSECHA = '2021' AND MES_CLIENTE = '9' AND YEAR_CLIENTE = '2021'

SELECT * FROM CASOS_RAROS_REVISAR*/

/*DELETE FROM BD_COSECHAS_REPORTING
WHERE CUSTOMER_ID = '1313737752' AND MES_COSECHA = '1' AND YEAR_COSECHA = '2022' 
				AND CLTE_COSECHA = 0 AND MES_CLIENTE = '12' AND YEAR_CLIENTE = '2021'

DELETE FROM BD_COSECHAS_REPORTING
WHERE CUSTOMER_ID = '1813729508' AND MES_COSECHA = '1' AND YEAR_COSECHA = '2022' 
				AND CLTE_COSECHA = 0 AND MES_CLIENTE = '12' AND YEAR_CLIENTE = '2021'

DELETE FROM BD_COSECHAS_REPORTING
WHERE CUSTOMER_ID = '193856884' AND MES_COSECHA = '1' AND YEAR_COSECHA = '2022' 
				AND CLTE_COSECHA = 0 AND MES_CLIENTE = '12' AND YEAR_CLIENTE = '2021'

DELETE FROM BD_COSECHAS_REPORTING
WHERE CUSTOMER_ID = '1212944392' AND MES_COSECHA = '2' AND YEAR_COSECHA = '2022' 
				AND CLTE_COSECHA = 0 AND MES_CLIENTE = '11' AND YEAR_CLIENTE = '2021'

DELETE FROM BD_COSECHAS_REPORTING
WHERE CUSTOMER_ID = '1212724122' AND MES_COSECHA = '10' AND YEAR_COSECHA = '2021' 
				AND CLTE_COSECHA = 0 AND MES_CLIENTE = '9' AND YEAR_CLIENTE = '2021'
*/

;

-- 4. CREANDO DATASET DE MODELO (MODELO_DATASET) // BGI = RET_M1 // VER DEFINICION EN ARCHIVO Pasos_Realizados_Analisis.TXT

WITH DB_INICIAL AS ( 
SELECT CUSTOMER_ID, IIF(MES_COSECHA = 12, 1, MES_COSECHA+1) AS MES_BGI
	   , MES_CLIENTE, IIF(IIF(MES_COSECHA = 12, 1, MES_COSECHA+1) = 1, YEAR_CLIENTE+1, YEAR_CLIENTE) AS YEAR_BGI
	   , YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA, ORD_ORDENES_TOTALES, ORD_ORDENES_COMPLETADAS
	   , ORD_ORDENES_COMPLETADAS_A_TIEMPO, ORD_ORDENES_COMPLETADAS_CON_RETRASO, ORD_ORDENES_CANCELADAS, ORD_ORDENES_OTROS, MNT_TOTAL_GMV, MNT_TOTAL_DESCUENTO, MNT_TOTAL_COSTO_ENVIO, MNT_TOTAL_COSTO_SERVICIO, MNT_TOTAL_PROPINA, MNT_PROM_GMV, MNT_PROM_DESCUENTO, MNT_PROM_COSTO_ENVIO, MNT_PROM_PROM_SERVICIO, MNT_PROM_PROPINA, MDP_TOT_ORDENES_CASH, MDP_TOT_ORDENES_TDC, MDP_TOT_ORDENES_PAGO_DIGITAL, MDP_TOT_ORDENES_PAGO_DIGITAL_RAPPI, MDP_TOT_TARJETA_DEBITO, MDP_TOT_TDC_NACIONAL, MDP_TOT_TDC_INTERNACIONAL, EXP_TIEMPO_ESPERA_EFECTIVO_M, EXP_TIEMPO_ESPERA_PROMETIDO_M, EXP_KPI_TIEMPO_ESPERA, EXP_ORDEN_CON_RECLAMO, EXP_ORDEN_SIN_RECLAMO, EXP_ORDENES_WEB, EXP_ORDENES_ANDROID, EXP_ORDENES_IOS
FROM BD_COSECHAS_REPORTING
WHERE CLTE_COSECHA = 1 AND (MES_COSECHA <> '2'))

, DB_TOTAL AS (
SELECT CUSTOMER_ID, MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA, ORD_ORDENES_TOTALES, ORD_ORDENES_COMPLETADAS, ORD_ORDENES_COMPLETADAS_A_TIEMPO, ORD_ORDENES_COMPLETADAS_CON_RETRASO, ORD_ORDENES_CANCELADAS, ORD_ORDENES_OTROS, MNT_TOTAL_GMV, MNT_TOTAL_DESCUENTO, MNT_TOTAL_COSTO_ENVIO, MNT_TOTAL_COSTO_SERVICIO, MNT_TOTAL_PROPINA, MNT_PROM_GMV, MNT_PROM_DESCUENTO, MNT_PROM_COSTO_ENVIO, MNT_PROM_PROM_SERVICIO, MNT_PROM_PROPINA, MDP_TOT_ORDENES_CASH, MDP_TOT_ORDENES_TDC, MDP_TOT_ORDENES_PAGO_DIGITAL, MDP_TOT_ORDENES_PAGO_DIGITAL_RAPPI, MDP_TOT_TARJETA_DEBITO, MDP_TOT_TDC_NACIONAL, MDP_TOT_TDC_INTERNACIONAL, EXP_TIEMPO_ESPERA_EFECTIVO_M, EXP_TIEMPO_ESPERA_PROMETIDO_M, EXP_KPI_TIEMPO_ESPERA, EXP_ORDEN_CON_RECLAMO, EXP_ORDEN_SIN_RECLAMO, EXP_ORDENES_WEB, EXP_ORDENES_ANDROID, EXP_ORDENES_IOS
FROM BD_COSECHAS_REPORTING
WHERE (MES_COSECHA IS NOT NULL) AND (YEAR_COSECHA IS NOT NULL) )

, DB_RETENIDOS_M1 AS (
SELECT B.YEAR_BGI, B.MES_BGI, A.*
FROM DB_TOTAL AS A INNER JOIN DB_INICIAL  AS B ON A.CUSTOMER_ID = B.CUSTOMER_ID AND (A.YEAR_CLIENTE = B.YEAR_BGI) AND (A.MES_CLIENTE = B.MES_BGI))

SELECT IIF(B.CUSTOMER_ID IS NULL,0,1) AS RET_M1, A.*
INTO MODELO_DATASET
FROM DB_INICIAL AS A LEFT JOIN DB_RETENIDOS_M1 AS B ON A.CUSTOMER_ID = B.CUSTOMER_ID


;

-- 5. CREANDO REPORTING INICIAL
-- 5.1 TOTAL USUARIOS Y COSECHAS
SELECT CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME) AS FECHA
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME)) AS FECHA_COSECHA
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA, COUNT(CUSTOMER_ID) AS CLIENTES
FROM BD_COSECHAS_REPORTING
GROUP BY CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME)
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME))
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA
ORDER BY FECHA ASC, FECHA_COSECHA ASC, YEAR_CLIENTE, MES_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA

-- 5.2 PART COSECHAS EN TOTAL USUARIOS MES
SELECT FECHA, FECHA_COSECHA, SUM(CLIENTES) AS TOTAL_USUARIOS, SUM(IIF(CLTE_COSECHA = 1, CLIENTES, 0)) AS USUARIOS_COSECHA
FROM (
SELECT CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME) AS FECHA
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME)) AS FECHA_COSECHA
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA, COUNT(CUSTOMER_ID) AS CLIENTES
FROM BD_COSECHAS_REPORTING
GROUP BY CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME)
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME))
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA
) AS A 
GROUP BY FECHA, FECHA_COSECHA
ORDER BY FECHA, FECHA_COSECHA

-- 5.3 RETENCION PROMEDIO, CHURN PROMEDIO Y ORDENES PROMEDIO POR COSECHA
; WITH COSECHA_1 AS (
SELECT IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2021, MES_CLIENTE-MES_COSECHA
	       , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2022, IIF(MES_CLIENTE = 1, 13,IIF(MES_CLIENTE = 2, 14, MES_CLIENTE))-MES_COSECHA
		   , IIF(YEAR_COSECHA = 2022, MES_CLIENTE - MES_COSECHA,NULL))) AS MES_RODANTE
	   , CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME) AS FECHA
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME)) AS FECHA_COSECHA
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA, COUNT(CUSTOMER_ID) AS CLIENTES
FROM BD_COSECHAS_REPORTING
WHERE CLTE_COSECHA = 1
GROUP BY CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME)
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME))
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA
	   , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2021, MES_CLIENTE-MES_COSECHA
	       , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2022, IIF(MES_CLIENTE = 1, 13,IIF(MES_CLIENTE = 2, 14, MES_CLIENTE))-MES_COSECHA
		   , IIF(YEAR_COSECHA = 2022, MES_CLIENTE - MES_COSECHA,NULL))) 
)

SELECT A.*, B.CLIENTES AS USUARIOS_COSECHA_M0, IIF(B.CLIENTES IS NULL, NULL, A.CLIENTES*1.0 / B.CLIENTES) AS RETENCION
FROM (
SELECT IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2021, MES_CLIENTE-MES_COSECHA
	       , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2022, IIF(MES_CLIENTE = 1, 13,IIF(MES_CLIENTE = 2, 14, MES_CLIENTE))-MES_COSECHA
		   , IIF(YEAR_COSECHA = 2022, MES_CLIENTE - MES_COSECHA,NULL))) AS MES_RODANTE
	   , CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME) AS FECHA
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME)) AS FECHA_COSECHA
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA, COUNT(CUSTOMER_ID) AS CLIENTES
	   , AVG(ORD_ORDENES_TOTALES*1.0) AS ORDENES_PROMEDIO
FROM BD_COSECHAS_REPORTING
WHERE CLTE_COSECHA IS NOT NULL
GROUP BY CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME)
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME))
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA
	   , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2021, MES_CLIENTE-MES_COSECHA
	       , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2022, IIF(MES_CLIENTE = 1, 13,IIF(MES_CLIENTE = 2, 14, MES_CLIENTE))-MES_COSECHA
		   , IIF(YEAR_COSECHA = 2022, MES_CLIENTE - MES_COSECHA,NULL))) 
) AS A LEFT JOIN COSECHA_1 AS B ON A.FECHA_COSECHA = B.FECHA_COSECHA

-- 5.4 INDICADORES POR COSECHA
; WITH COSECHA_1 AS (
SELECT IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2021, MES_CLIENTE-MES_COSECHA
	       , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2022, IIF(MES_CLIENTE = 1, 13,IIF(MES_CLIENTE = 2, 14, MES_CLIENTE))-MES_COSECHA
		   , IIF(YEAR_COSECHA = 2022, MES_CLIENTE - MES_COSECHA,NULL))) AS MES_RODANTE
	   , CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME) AS FECHA
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME)) AS FECHA_COSECHA
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA, COUNT(CUSTOMER_ID) AS CLIENTES
FROM BD_COSECHAS_REPORTING
WHERE CLTE_COSECHA = 1
GROUP BY CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME)
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME))
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA
	   , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2021, MES_CLIENTE-MES_COSECHA
	       , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2022, IIF(MES_CLIENTE = 1, 13,IIF(MES_CLIENTE = 2, 14, MES_CLIENTE))-MES_COSECHA
		   , IIF(YEAR_COSECHA = 2022, MES_CLIENTE - MES_COSECHA,NULL))) 
)

SELECT A.*, B.CLIENTES AS USUARIOS_COSECHA_M0, IIF(B.CLIENTES IS NULL, NULL, A.CLIENTES*1.0 / B.CLIENTES) AS RETENCION
FROM (
SELECT IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2021, MES_CLIENTE-MES_COSECHA
	       , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2022, IIF(MES_CLIENTE = 1, 13,IIF(MES_CLIENTE = 2, 14, MES_CLIENTE))-MES_COSECHA
		   , IIF(YEAR_COSECHA = 2022, MES_CLIENTE - MES_COSECHA,NULL))) AS MES_RODANTE
	   , CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME) AS FECHA
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME)) AS FECHA_COSECHA
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA, COUNT(CUSTOMER_ID) AS CLIENTES
	   , SUM(ORD_ORDENES_TOTALES*1.0) AS ORDENES_TOTALES
	   , SUM([ORD_ORDENES_COMPLETADAS_A_TIEMPO]*1.0) AS ORDENES_TOT_COMPLETADAS_A_TIEMPO
	   , SUM([ORD_ORDENES_COMPLETADAS_CON_RETRASO]*1.0) AS ORDENES_TOT_COMPLETADAS_CON_RETRASO
	   , SUM([ORD_ORDENES_CANCELADAS]*1.0) AS ORDENES_TOT_CANCELADAS
	   , SUM([ORD_ORDENES_OTROS]*1.0) AS ORDENES_TOT_OTROS
	   , SUM([MDP_TOT_ORDENES_CASH]) AS ORDENES_CASH
	   , SUM([MDP_TOT_ORDENES_TDC]) AS ORDENES_TDC
	   , SUM([MDP_TOT_ORDENES_PAGO_DIGITAL]) AS ORDENES_PAGO_DIGITAL
	   , SUM([MDP_TOT_ORDENES_PAGO_DIGITAL_RAPPI]) AS ORDENES_PAGO_DIGITAL_RAPPI
	   , AVG([EXP_TIEMPO_ESPERA_EFECTIVO_M]*1.0) AS EXP_TIEMPO_ESPERA_EFECTIVO
	   , AVG([EXP_TIEMPO_ESPERA_PROMETIDO_M]*1.0) AS EXP_TIEMPO_ESPERA_PROMETIDO
	   , AVG([EXP_KPI_TIEMPO_ESPERA]*1.0) AS EXP_KPI_TIEMPO_ESPERA
	   , SUM([EXP_ORDEN_CON_RECLAMO]) ORDENES_CON_RECLAMO
	   , SUM([EXP_ORDEN_SIN_RECLAMO]) ORDENES_SIN_RECLAMO
	   , AVG([MNT_PROM_GMV]) AVG_GMV
	   , AVG([MNT_PROM_DESCUENTO]) AS AVG_DESCUENTO
FROM BD_COSECHAS_REPORTING
WHERE CLTE_COSECHA IS NOT NULL
GROUP BY CAST(CONCAT(YEAR_CLIENTE,'-', MES_CLIENTE,'-01') AS SMALLDATETIME)
	   , IIF( YEAR_COSECHA IS NULL, NULL, CAST(CONCAT(YEAR_COSECHA,'-', MES_COSECHA,'-01') AS SMALLDATETIME))
	   , MES_CLIENTE, YEAR_CLIENTE, MES_COSECHA, YEAR_COSECHA, CLTE_COSECHA
	   , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2021, MES_CLIENTE-MES_COSECHA
	       , IIF(YEAR_COSECHA = 2021 AND YEAR_CLIENTE = 2022, IIF(MES_CLIENTE = 1, 13,IIF(MES_CLIENTE = 2, 14, MES_CLIENTE))-MES_COSECHA
		   , IIF(YEAR_COSECHA = 2022, MES_CLIENTE - MES_COSECHA,NULL))) 
) AS A LEFT JOIN COSECHA_1 AS B ON A.FECHA_COSECHA = B.FECHA_COSECHA




-- FIN --

-- NOTAS VARIAS --
--, IIF(CREATED_AT = '1753-01-01 00:00:00.000', NULL, CREATED_AT) AS CREATED_AT
--, IIF(RT_ARRIVE_AT='1753-01-01 00:00:00.000', NULL, RT_ARRIVE_AT) AS RT_ARRIVE_AT
--, IIF(ETA = '1753-01-01 00:00:00.000', NULL, ETA) AS ETA
--, 5 registros raros de clientes