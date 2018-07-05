class Coin

    attr_accessor :id, :name, :symbol, :market_cap, :price, :supply, :change_in_24h, :ranking
    def initialize(hash)
        update_obj(hash)
    end

    def update_obj(name: nil, symbol: nil, market_cap: nil, price: nil, supply: nil, change_in_24h: nil, ranking: nil, id: nil)
        @id                = id
        @name              = name.downcase
        @symbol            = symbol.downcase
        self.market_cap    = market_cap
        self.price         = price
        self.supply        = supply
        self.change_in_24h = change_in_24h
        @ranking           = ranking
    end

    def name
        @name.capitalize
    end

    def symbol
        @symbol.upcase
    end

    def price
        "$#{separate_comma(price_f)}"
    end

    def price_f
        @price / 1000000.0
    end

    def price=(p)
        temp   = p.match(/\$([\d|,]+\.*\d*)/) if p.is_a? String
        @price = temp ? temp[1].to_f * 1000000 : p
    end

    def market_cap
        "$#{separate_comma(@market_cap / 100.0)}"
    end

    def market_cap=(m)
        temp        = m.match(/\$([\d|,]+)/) if m.is_a? String
        @market_cap = temp ? temp[1].split(",").join("").to_f * 100 : m
    end

    def change_in_24h
        "#{separate_comma(@change_in_24h / 1000.0)}%"
    end
    
    def change_in_24h=(c)
        temp           = c.match(/([\d|\.|-]+)%/) if c.is_a? String
        @change_in_24h = temp ? temp[1].to_f * 1000 : c
    end

    def supply
        separate_comma(@supply)
    end

    def supply=(s)
        temp    = s.match(/([\d|,]+).*/) if s.is_a? String
        @supply = temp ? temp[1].split(",").join("").to_i : s
    end
    
    def exists?
        coin     = DB[:conn].execute("SELECT * FROM coins WHERE name = ? AND symbol = ?;", name, symbol)
        self.id || (!coin.empty? && @id = coin[0][0])
    end

    def save
        if exists?
            update
        else
            insert
        end
    end

    def pretty
        "Price of #{name}(#{symbol}) is #{price}"
    end
    def self.create(option={})
        coin = self.new(option)
        coin.save
    end

    def self.create_from_row(row=[], id=nil)
        self.new_from_row(row, id).save
    end

    def self.create_table
        sql = <<-SQL
            CREATE TABLE IF NOT EXISTS coins(
                id            INTEGER PRIMARY KEY,
                name          TEXT,
                symbol        TEXT,
                price         INTEGER,
                market_cap    INTEGER,
                supply        INTEGER,
                change_in_24h INTEGER,
                ranking       INTEGER,
                last_modified INTEGER
            );
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        DB[:conn].execute("DROP TABLE IF EXISTS coins;")
    end

    def self.row_to_hash(row, id = nil)
        {
            id: id,
            name: row[0],
            symbol: row[1],
            price: row[2],
            market_cap: row[3],
            supply: row[4],
            change_in_24h: row[5],
            ranking: row[6]

        }
    end

    def self.new_from_row(row, id = nil)
        self.new(row_to_hash(row, id))
    end

    def self.all
        sql = <<-SQL
        SELECT * FROM coins;
        SQL
        DB[:conn].execute(sql).map { |row| new_from_row(row[1..-2], row[0]) }
    end

    def self.find?(option)
        option &&= option.downcase
        id, *coin = DB[:conn].execute("SELECT * FROM coins WHERE name = ? OR symbol = ?;", option, option).first
        if id && !coin.empty? 
            self.new_from_row(coin, id) 
        else
            puts "Sorry no coin by name or symbol of #{option}."
        end
    end
    
    def self.order_by(option={ranking: "ASC"})
        option = option.to_a.first
        sql    = <<-SQL
            SELECT * FROM 
                (SELECT * FROM coins ORDER BY last_modified DESC LIMIT 100) 
            ORDER BY #{option[0]} #{option[1]};
        SQL
        DB[:conn].execute(sql).map { |row| new_from_row(row[1..-2], row[0]) }
    end

    private
    def separate_comma(number)
        whole, decimal = number.to_s.split(".")
        whole_with_commas = whole.chars.to_a.reverse.each_slice(3).map(&:join).join(",").reverse
        [whole_with_commas, decimal].compact.join(".")
    end

    def insert
        sql = <<-SQL
            INSERT INTO coins(name, symbol, market_cap, price, supply, change_in_24h, ranking, last_modified) 
            VALUES(?, ?, ?, ?, ?, ?, ?, datetime("now"));
        SQL
        DB[:conn].execute(sql, @name, @symbol, @market_cap, @price, @supply, @change_in_24h, @ranking)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM coins;")[0][0]
        self
    end
    def update
        sql = <<-SQL
            UPDATE coins SET
                name           = ?
              , symbol         = ?
              , market_cap     = ?
              , price          = ?
              , supply         = ?
              , change_in_24h  = ?
              , ranking        = ?
              , last_modified  = datetime("now")
            WHERE
                id = ?
        SQL
        DB[:conn].execute(sql, @name, @symbol, @market_cap, @price, @supply, @change_in_24h, @ranking, @id)
        self
    end
end