require 'logger'
require 'sequel'

class Runway

  DATABASE_CONFIG = YAML.load_file("config/database.yml")

  API_DB = Sequel.connect(adapter: DATABASE_CONFIG['adapter'],
        host: DATABASE_CONFIG['host'],
        database: DATABASE_CONFIG['api_database'],
        user: DATABASE_CONFIG['user'],
        password: DATABASE_CONFIG['password']
      )

  GPS_DB ||= Sequel.connect(adapter: DATABASE_CONFIG['adapter'],
        host: DATABASE_CONFIG['host'],
        database: DATABASE_CONFIG['gps_database'],
        user: DATABASE_CONFIG['user'],
        password: DATABASE_CONFIG['password']
      )

  def self.perform
    logger.info(" ===== RUNWAY PROCESS START =====")
    check_for_new_positions
    logger.info(" ===== RUNWAY PROCESS END =====")
  end

  def self.check_for_new_positions
    units_with_last_location.all.each do |unit|
      position = positions[unit[:imei].to_s]
      if position && position[:created_at] > unit[:created_at]
        add_location(unit[:id], position[:latitude], position[:longitude])
      else
        logger.info(" NO NEW POSITION FOR DEVICE - #{unit[:imei].to_s} - ")
      end
    end
  end

  def self.add_location(unit_id, latitude, longitude)
    insert = API_DB["INSERT INTO \"Locations\" (id, unit_id, location, created_at, updated_at)
      VALUES (uuid_in(md5(random()::text || now()::text)::cstring), ?, ST_GeomFromText('POINT(? ?)', 4326), ?, ?)",
      unit_id, latitude, longitude, Time.now, Time.now]
    insert.insert
    logger.info "NEW POSITION (#{latitude}, #{longitude}) FOR UNIT (#{unit_id})"
  end

  def self.positions
    positions_hash = {}
    get_recent_positions.all.each do |position|
      imei = position.delete(:imei)
      positions_hash[imei] = position
    end
    positions_hash
  end

  def self.units_with_last_location
    API_DB['SELECT "Units".id, "Units".imei, locations.created_at FROM "Units" INNER JOIN
      (SELECT DISTINCT(unit_id) as unit_id, MAX(created_at) as created_at FROM "Locations"
      GROUP BY unit_id) as locations ON "Units".id = locations.unit_id WHERE "Units".imei IS NOT NULL']
  end

  def self.get_recent_positions
    GPS_DB['SELECT devices.uniqueid as imei, positions.latitude, positions.longitude, positions.created_at FROM devices
      INNER JOIN (SELECT latitude, longitude, positions.deviceid, positions.servertime as created_at FROM positions
      INNER JOIN (SELECT DISTINCT(deviceid), MAX(id) as id FROM positions GROUP BY deviceid) AS max_positions
      ON positions.id = max_positions.id) AS positions ON devices.id = positions.deviceid']
  end

  def self.logger
    @@logger ||= Logger.new('runway.log')
  end

end