class GetWeekNumber < ActiveRecord::Migration[5.2]
  tag :predeploy
  execute(<<-CODE)
    DROP FUNCTION if exists adempiere.get_week_number(start_period timestamp without time zone, date_operation timestamp without time zone);
CREATE FUNCTION adempiere.get_week_number(
	start_period timestamp without time zone,
	date_operation timestamp without time zone)
    RETURNS integer
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
DECLARE
   week_number	      integer;
   residue            integer;
   difference	      integer;
BEGIN

	difference:= DATE(date_operation) - DATE(start_period) + 1;
	week_number:= difference/7;
	residue := difference % 7;
	IF residue > 0 THEN
		week_number:= week_number + 1;
	END IF;
   RETURN week_number;

END;
$BODY$;
  CODE
end
