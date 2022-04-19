class AddPopulationFiguresToRegionsAndConstituencies < ActiveRecord::Migration[6.1]
  class Constituency < ActiveRecord::Base; end
  class Region < ActiveRecord::Base; end

  CONSTITUENCIES = {
    "W09000001" => { population: 70043 },
    "W09000002" => { population: 62829 },
    "W09000003" => { population: 59177 },
    "W09000004" => { population: 73508 },
    "W09000005" => { population: 72505 },
    "W09000006" => { population: 70093 },
    "W09000007" => { population: 86007 },
    "W09000008" => { population: 71250 },
    "W09000009" => { population: 72416 },
    "W09000010" => { population: 61731 },
    "W09000011" => { population: 63264 },
    "W09000012" => { population: 72695 },
    "W09000014" => { population: 79620 },
    "W09000015" => { population: 73116 },
    "W09000016" => { population: 78307 },
    "W09000017" => { population: 83546 },
    "W09000018" => { population: 79772 },
    "W09000019" => { population: 83096 },
    "W09000020" => { population: 84125 },
    "W09000021" => { population: 74500 },
    "W09000022" => { population: 68815 },
    "W09000023" => { population: 85504 },
    "W09000025" => { population: 69739 },
    "W09000026" => { population: 71329 },
    "W09000029" => { population: 94174 },
    "W09000031" => { population: 93919 },
    "W09000034" => { population: 86627 },
    "W09000035" => { population: 88270 },
    "W09000036" => { population: 76603 },
    "W09000037" => { population: 84075 },
    "W09000038" => { population: 69862 },
    "W09000039" => { population: 90070 },
    "W09000040" => { population: 82455 },
    "W09000041" => { population: 69171 },
    "W09000042" => { population: 91158 },
    "W09000043" => { population: 117671 },
    "W09000044" => { population: 76528 },
    "W09000045" => { population: 77588 },
    "W09000046" => { population: 84153 },
    "W09000047" => { population: 103568 }
  }

  REGIONS = {
    "W10000001" => { population: 637828 },
    "W10000006" => { population: 581450 },
    "W10000007" => { population: 725711 },
    "W10000008" => { population: 654490 },
    "W10000009" => { population: 553400 }
  }

  def change
    add_column :constituencies, :population, :integer
    add_column :regions, :population, :integer

    up_only do
      Constituency.update(CONSTITUENCIES.keys, CONSTITUENCIES.values)
      Region.update(REGIONS.keys, REGIONS.values)

      change_column_null :constituencies, :population, false
      change_column_null :regions, :population, false
    end
  end
end
