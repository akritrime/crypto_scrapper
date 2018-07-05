class CryptoScrapper
    def initialize(index_url)
        @doc = Nokogiri::HTML(open(index_url))
    end

    def call
        Coin.drop_table
        Coin.create_table
        rows.map{ |row| Coin.create_from_row(row) }
    end
    
    private 
    def rows
        @rows ||= @doc.css("#currencies>tbody tr").map do |coin_data|
            [
                ".currency-name-container",
                ".currency-symbol",
                ".price",
                ".market-cap",
                ".circulating-supply",
                ".percent-24h"
            ].map { |el| coin_data.css(el).text.strip } << coin_data.css("td").first.text.strip
        end
    end
    
end
 