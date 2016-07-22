CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_isochrone(username TEXT, orgname TEXT, source geometry(Geometry, 4326), mode TEXT, range integer[], options text[] DEFAULT array[]::text[])
RETURNS SETOF cdb_dataservices_server.isoline AS $$
  plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
  redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
  plpy.execute("SELECT cdb_dataservices_server._get_isolines_routing_config({0}, {1})".format(plpy.quote_nullable(username), plpy.quote_nullable(orgname)))
  user_isolines_config = GD["user_isolines_routing_config_{0}".format(username)]
  type = 'isochrone'

  if user_isolines_config.google_services_user:
    plpy.error('This service is not available for google service users.')

  here_plan = plpy.prepare("SELECT * FROM cdb_dataservices_server._cdb_here_routing_isolines($1, $2, $3, $4, $5, $6, $7) as isoline; ", ["text", "text", "text", "geometry(Geometry, 4326)", "text", "integer[]", "text[]"])
  result = plpy.execute(here_plan, [username, orgname, type, source, mode, range, options])
  return result
$$ LANGUAGE plpythonu;


-- mapzen isochrones
CREATE OR REPLACE FUNCTION cdb_dataservices_server.cdb_mapzen_isochrone(username TEXT, orgname TEXT, source geometry(Geometry, 4326), mode TEXT, range integer[], options text[] DEFAULT array[]::text[])
RETURNS SETOF cdb_dataservices_server.isoline AS $$
  plpy.execute("SELECT cdb_dataservices_server._connect_to_redis('{0}')".format(username))
  redis_conn = GD["redis_connection_{0}".format(username)]['redis_metrics_connection']
  plpy.execute("SELECT cdb_dataservices_server._get_mapzen_isolines_config({0}, {1})".format(plpy.quote_nullable(username), plpy.quote_nullable(orgname)))
  user_isolines_config = GD["user_mapzen_isolines_routing_config_{0}".format(username)]
  type = 'isochrone'

  mapzen_plan = plpy.prepare("SELECT * FROM cdb_dataservices_server._cdb_mapzen_isolines($1, $2, $3, $4, $5, $6, $7) as isoline; ", ["text", "text", "text", "geometry(Geometry, 4326)", "text", "integer[]", "text[]"])
  result = plpy.execute(mapzen_plan, [username, orgname, type, source, mode, range, options])

  return result
$$ LANGUAGE plpythonu;
