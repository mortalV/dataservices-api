-- Mock the server function
CREATE OR REPLACE FUNCTION cdb_geocoder_server.geocode_admin0_polygon(user_id name, tx_id bigint, country_name text)
RETURNS Geometry AS $$
BEGIN
  RAISE NOTICE 'cdb_geocoder_server.geocode_admin0_polygon invoked with params (%, %, %)', user_id, 'some_transaction_id', country_name;
  RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';


-- Exercise the public and the proxied function
SELECT cdb_geocoder_client.geocode_admin0_polygon('Spain');