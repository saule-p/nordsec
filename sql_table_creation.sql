DROP TEMPORARY TABLE IF EXISTS temp_messages_1;

CREATE TEMPORARY TABLE temp_messages_1 AS
SELECT 
	id,
    url,
    date,
    source,
    protocol,
    response_code,
    load_time_seconds,
	COALESCE(
		domain_age_years,
		LAG(domain_age_years) OVER (PARTITION BY url, source, service ORDER BY date DESC)
	) AS domain_age_years,
    page_size_kb,
    redirects,
    service,
    redirect_count
FROM nordsec.messages;

DROP TEMPORARY TABLE IF EXISTS temp_messages_2;

CREATE TEMPORARY TABLE temp_messages_2 AS
SELECT 
	id,
	url,
	date,
	source,
	protocol,
	response_code,
	load_time_seconds, 
	COALESCE(
		domain_age_years,
		LEAD(domain_age_years) OVER (PARTITION BY url, source, service ORDER BY date DESC)
	) AS domain_age_years,
	page_size_kb,
	redirects,
	service,
	redirect_count
FROM nordsec.temp_messages_1;

DROP TEMPORARY TABLE IF EXISTS temp_messages_3;

CREATE TEMPORARY TABLE temp_messages_3 AS
SELECT 
	url,
	MAX(YEAR(date)) - MIN(YEAR(date)) as true_domain_age_years
FROM nordsec.temp_messages_2
WHERE YEAR(DATE) > '2019'
GROUP BY 
	url;

CREATE TABLE data_messages AS
SELECT 
	msg.id,
	msg.url,
	msg.date,
	msg.source,
	msg.protocol,
	msg.response_code,
	msg.load_time_seconds,
	msg.domain_age_years,
	tr_yrs.true_domain_age_years,
	msg.page_size_kb,
	msg.service,
	msg.redirect_count,
	msg.redirects,
	rep.reputation_source,
	rep.reputation_score,
	rep.reputation_category,
	rep.reputation_date,
	tr_rep.true_reputation,
	tr_rep.timestamp AS rep_timestamp,
	pri.priority,
	pri.timestamp AS pri_timestamp
FROM nordsec.temp_messages_2 AS msg
LEFT JOIN nordsec.reputations AS rep 
	ON msg.id = rep.id
LEFT JOIN nordsec.true_reputations AS tr_rep 
	ON msg.id = tr_rep.id
LEFT JOIN nordsec.priority AS pri 
	ON pri.id = msg.id 
LEFT JOIN nordsec.temp_messages_3 tr_yrs 
	ON msg.url = tr_yrs.url;

select * from data_messages;

DROP TEMPORARY TABLE IF EXISTS true_priority;

CREATE TEMPORARY TABLE true_priority AS
SELECT 
	main.url,
	main.priority,
	b.source,
	b.reputation_score,
	b.reputation_category,
	b.reputation_date,
	b.true_reputation,
	b.rep_timestamp,
	ROW_NUMBER() OVER (PARTITION BY url, source, priority ORDER BY reputation_date DESC) AS rn
FROM (
	SELECT 
		DISTINCT url,
		priority,
		source,
		MAX(pri_timestamp) AS max_timestamp
	FROM data_messages
	GROUP BY 
		url,
		priority,
		source
    ) main
LEFT JOIN data_messages b 
	ON main.url = b.url 
	AND main.priority = b.priority 
	AND main.max_timestamp = b.pri_timestamp 
	AND main.source=b.source;

DROP TABLE IF EXISTS master_data_messages;

CREATE TABLE master_data_messages AS
SELECT 
	id, 
	main.url,
	date,
	main.source,
	protocol,
	response_code,
	load_time_seconds,
	domain_age_years,
	true_domain_age_years,
	page_size_kb,
	service,
	redirect_count,
	redirects,
	COALESCE(main.reputation_source, b.source) AS reputation_source,
	COALESCE(main.reputation_score, b.reputation_score) AS reputation_score,
	COALESCE(main.reputation_category, b.reputation_category) AS reputation_category,
	COALESCE(main.reputation_date, b.reputation_date) AS reputation_date,
	COALESCE(main.true_reputation, b.true_reputation) AS true_reputation,
	COALESCE(main.rep_timestamp, b.rep_timestamp) AS rep_timestamp,
	main.priority,
	pri_timestamp
	FROM data_messages main
LEFT JOIN true_priority b 
	ON main.url=b.url 
    AND main.priority = b.priority 
    AND main.source=b.source 
    AND b.rn = 1;
    
CREATE INDEX idx_url ON nordsec.master_data_messages(url(255));