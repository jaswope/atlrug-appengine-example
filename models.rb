require 'dm-core'
require 'appengine-apis/datastore'
require 'appengine-apis/memcache'
DataMapper.setup(:default, "appengine://auto")
NUM_SHARDS = 20


class Counter
  class << self
    def increment(name)
      shard_num = rand(NUM_SHARDS)
      shard_name = "#{name}#{shard_num}"
      shard_key = AppEngine::Datastore::Key.from_path(self.to_s, shard_name)
      AppEngine::Datastore.transaction do
        begin
          shard = AppEngine::Datastore.get shard_key
        rescue AppEngine::Datastore::EntityNotFound
          shard = AppEngine::Datastore::Entity.new(shard_key)
          shard["count"] = 0
          shard["counter"] = name
        end
        shard.set_property("count", shard["count"] + 1)
        AppEngine::Datastore.put(shard)
      end
      memcache.incr(name)
    end

    def get_count(name)
      unless count = memcache.get(name)
        query = AppEngine::Datastore::Query.new(self.to_s)
        query.filter("counter", "==", name)
        count = query.iterator.inject(0) {|sum, e| sum += e["count"]}
        memcache.set(name, count)
      end
      count
    end

    def memcache_name(name)
      memcache_name = "Counter::#{name}" 
    end

    def stats
      memcache.stats
    end
    
    def memcache
      @memcache ||= AppEngine::Memcache.new(:namespace => self.to_s)
    end
  end
end

class  UserInfo
  include DataMapper::Resource

  property :id, Serial
  property :views, Integer, :default => 0
  property :appengine_user_id, String, :required => true

end

