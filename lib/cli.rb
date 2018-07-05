class Cli
    def initialize(opts)
        @opts = opts
    end
    def coin
        coins = @opts[:coins]
        unless coins.empty?
            coins.map { |coin| Coin.find?(coin) }
                .compact
                .uniq(&:id)
                .each { |coin| puts coin.pretty }
            exit
        end
    end

    def exch
        if @opts[:exch]
            if @opts[:to] && @opts[:from] && @opts[:amount]
                to = Coin.find?(@opts[:to])
                from = Coin.find?(@opts[:from])
                amount = @opts[:amount].to_f
                res = (amount * from.price_f) / (to.price_f)
                puts "#{amount} #{from.symbol} = #{res.round(3)} #{to.symbol}"
            else
                puts "Convertion needs the option --to, --from, and --amount."
            end
            exit
        end  
    end

    def run
        coin
        exch
    end

    def self.start
        opts = Slop.parse do |o|
            begin
                o.array '-c', '--coins', 'coins symbol or name'
                o.bool '-e', '--exch', 'converts an amount of certain crypto to another. Needs the --to, --from, and --amount options.'
                o.int '-a', '--amount', 'amount to convert'
                o.string '-t', '--to', 'cryptocurrency to convert to'
                o.string '-f', '--from', 'cryptocurrency to convert from'
                o.on '--sync', 'sync with present price' do
                    CryptoScrapper.new("https://coinmarketcap.com/").call
                    puts "Synced."
                    exit
                end
                o.on '-h', '--help', 'help' do
                    puts o
                    exit
                end
            rescue
                puts o
            end 
        end
        # opts[:arr].split(" ").join("").split(",").each {|e| puts e}
        # exit
        self.new(opts).run
    end
end