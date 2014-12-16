\set extname elephant_worker
\set extschema scheduler
\set dummy dummy
drop extension if exists :extname cascade;
create extension :extname with schema :extschema;
SELECT oid AS datoid FROM pg_database WHERE datname=current_catalog;
\gset
INSERT INTO :extschema.my_job (job_command, datoid, schedule) VALUES
('SELECT 1', :datoid, '0 0            1 1 0'),
('SELECT 1', :datoid, '* 0            * 1 0'),
('SELECT 1', :datoid, '*/12 0         * 1 0'),
('SELECT 1', :datoid, '*/12,*/11    0 * 1 0'),
('SELECT 1', :datoid, '*/12,30-40/3 0 * 11 0'),
('SELECT 1', :datoid, '@hourly'),
('SELECT 1', :datoid, '1-59/7 1 * 1 1');
set search_path=:extschema,public;
DO
$$
DECLARE
    allowed_combi int [][];
    roloids int [];
    datoid oid;
    job_count int := 1000;
    rolcount integer;
    minute int;
    hour int;
    dom int;
    dow int;
    month int;
BEGIN
    SELECT oid
      INTO datoid
      FROM pg_catalog.pg_database
     WHERE datname=current_catalog;
    roloids := array(SELECT oid
                       FROM pg_catalog.pg_roles pr
                      WHERE has_database_privilege(pr.oid, datoid, 'CONNECT')
                );
    rolcount := array_length(roloids,1);

    FOR i in 1..job_count LOOP
        IF i%10000 = 0 THEN
            RAISE NOTICE 'Inserted % jobs', i;
        END IF;
        minute := (random()*59)::int;
        hour   := (random()*23)::int;
        dom    := (random()*30)::int+1;
        dow    := (random()*6)::int;
        month  := (random()*11)::int+1;

        INSERT INTO job(schedule, datoid, roloid, job_command)
        VALUES (minute||' '||hour||' '||dom||' '||month||' '||dow, datoid, roloids[i%rolcount], i);
    END LOOP;
END;
$$;

VACUUM ANALYZE job;
