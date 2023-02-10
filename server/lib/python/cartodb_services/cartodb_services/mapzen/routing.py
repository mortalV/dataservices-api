import requests
import json
import re

from requests.adapters import HTTPAdapter
from cartodb_services.tools.exceptions import (WrongParams,
                                               MalformedResult,
                                               ServiceException)
from cartodb_services.tools.qps import qps_retry
from cartodb_services.tools import Coordinate, PolyLine
from cartodb_services.metrics import MetricsDataGatherer, Traceable


class MapzenRouting(Traceable):
    'A Mapzen Routing wrapper for python'

    PRODUCTION_ROUTING_BASE_URL = 'https://valhalla.mapzen.com/route'
    READ_TIMEOUT = 60
    CONNECT_TIMEOUT = 10
    MAX_RETRIES=1

    ACCEPTED_MODES = {
        "walk": "pedestrian",
        "car": "auto",
        "public_transport": "bus",
        "bicycle": "bicycle"
    }

    AUTO_SHORTEST = 'auto_shortest'

    OPTIONAL_PARAMS = [
        'mode_type',
    ]

    METRICS_UNITS = 'kilometers'
    IMPERIAL_UNITS = 'miles'

    def __init__(self, app_key, logger, service_params=None):
        service_params = service_params or {}
        self._app_key = app_key
        self._logger = logger
        self._url = service_params.get('base_url', self.PRODUCTION_ROUTING_BASE_URL)
        self._connect_timeout = service_params.get('connect_timeout', self.CONNECT_TIMEOUT)
        self._read_timeout = service_params.get('read_timeout', self.READ_TIMEOUT)
        self._max_retries = service_params.get('max_retries', self.MAX_RETRIES)

    @qps_retry
    def calculate_route_point_to_point(self, waypoints, mode,
                                       options=[], units=METRICS_UNITS):
        parsed_options = self.__parse_options(options)
        mode_param = self.__parse_mode_param(mode, parsed_options)
        directions = self.__parse_directions(waypoints)
        json_request_params = self.__parse_json_parameters(directions,
                                                           mode_param,
                                                           units)
        request_params = self.__parse_request_parameters(json_request_params)
        # TODO Extract HTTP client wrapper
        session = requests.Session()
        session.mount(self._url, HTTPAdapter(max_retries=self._max_retries))
        response = session.get(self._url, params=request_params,
                                timeout=(self._connect_timeout, self._read_timeout))
        self.add_response_data(response, self._logger)
        if response.status_code == requests.codes.ok:
            return self.__parse_routing_response(response.text)
        elif response.status_code == requests.codes.bad_request:
            return MapzenRoutingResponse(None, None, None)
        else:
            self._logger.error('Error trying to calculate route using Mapzen',
                               data={"response_status": response.status_code,
                                     "response_reason": response.reason,
                                     "response_content": response.text,
                                     "reponse_url": response.url,
                                     "response_headers": response.headers,
                                     "waypoints": waypoints, "mode": mode,
                                     "options": options})
            raise ServiceException('Error trying to calculate route using Mapzen', response)

    def __parse_options(self, options):
        return dict(option.split('=') for option in options)

    def __parse_request_parameters(self, json_request):
        request_options = {"json": json_request}
        request_options.update({'api_key': self._app_key})

        return request_options

    def __parse_json_parameters(self, directions, mode, units):
        json_options = directions
        json_options.update({'costing': self.ACCEPTED_MODES[mode]})
        json_options.update({"directions_options": {'units': units,
                             'narrative': False}})

        return json.dumps(json_options, ensure_ascii = False, separators=(',', ':'))

    def __parse_directions(self, waypoints):
        path = []
        for idx, point in enumerate(waypoints):
            if idx == 0 or idx == len(waypoints) - 1:
              point_type = 'break'
            else:
              point_type = 'through'
            path.append({"lon": str(point.longitude), "lat": str(point.latitude), "type": point_type})

        return {"locations": path}

    def __parse_routing_response(self, response):
        try:
            parsed_json_response = json.loads(response)
            legs = parsed_json_response['trip']['legs'][0]
            shape = PolyLine().decode(legs['shape'])
            length = legs['summary']['length']
            duration = legs['summary']['time']
            return MapzenRoutingResponse(shape, length, duration)
        except IndexError:
            return []
        except KeyError:
            raise MalformedResult()

    def __parse_mode_param(self, mode, options):
        if mode in self.ACCEPTED_MODES:
            mode_source = self.ACCEPTED_MODES[mode]
        else:
            raise WrongParams("{0} is not an accepted mode type".format(mode))

        if mode == self.ACCEPTED_MODES['car'] and 'mode_type' in options and \
                options['mode_type'] == 'shortest':
            mode = self.AUTO_SHORTEST

        return mode


class MapzenRoutingResponse:

    def __init__(self, shape, length, duration):
        self._shape = shape
        self._length = length
        self._duration = duration

    @property
    def shape(self):
        return self._shape

    @property
    def length(self):
        return self._length

    @property
    def duration(self):
        return self._duration
