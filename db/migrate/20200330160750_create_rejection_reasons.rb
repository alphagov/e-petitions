class CreateRejectionReasons < ActiveRecord::Migration[5.2]
  class RejectionReason < ActiveRecord::Base; end

  def change
    create_table :rejection_reasons, id: :serial do |t|
      t.string :code, limit: 30, null: false
      t.string :title, limit: 100, null: false
      t.string :description_en, limit: 2000, null: false
      t.string :description_cy, limit: 2000, null: false
      t.boolean :hidden, null: false, default: false
      t.timestamps null: false
    end

    up_only do
      {
        "insufficient" =>[
          "Not enough signatures",
          "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in the Senedd.",
          "Ni chasglwyd digon o lofnodion i gyfeirio’r ddeiseb at y Pwyllgor Deisebau.\n\nMae angen o leiaf 50 llofnod ar ddeiseb cyn y gellir ei hystyried yn y Senedd.",
          false
        ],
        "duplicate" =>[
          "Duplicate petition",
          "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
          "Mae deiseb yn bodoli eisoes ar y mater hwn. Ni allwn dderbyn deiseb newydd os oes un yn bodoli eisoes ar fater tebyg iawn, neu os yw’r Pwyllgor Deisebau wedi ystyried deiseb debyg yn ystod y flwyddyn ddiwethaf.",
          false
        ],
        "irrelevant" =>[
          "Not the Senedd/Government’s responsibility",
          "It’s about something that the Senedd or Welsh Government is not responsible for.",
          "Mae’n ymwneud â rhywbeth nad yw’r Senedd na Llywodraeth Cymru yn gyfrifol amdano.",
          false
        ],
        "no-action" =>[
          "Action unclear",
          "It’s not clear what the petition is asking the Senedd or Welsh Government to do.\n\nPetitions need to call on the Senedd or Government to take a specific action.",
          "Nid yw’n glir beth mae’r ddeiseb yn gofyn i’r Senedd neu Lywodraeth Cymru ei wneud.\n\nMae angen i ddeisebau alw ar y Senedd neu’r Llywodraeth i gymryd camau penodol.",
          false
        ],
        "fake-name" =>[
          "Incomplete name or details",
          "People who create petitions are required to provide a full, real name, as well as their address and contact details. Sorry if this wasn’t clear to you.\n\nWe are rejecting your petition for that reason, but if you resubmit your petition with a full name and contact details, we may able to approve it.",
          "Rhaid i unrhyw un sy’n creu deiseb nodi ei enw go iawn yn llawn, ynghyd â’i gyfeiriad a’i fanylion cyswllt. Mae’n ddrwg gennym os nad oedd hynny’n glir i chi.\n\nRydym yn gwrthod eich deiseb am y rheswm hwnnw, ond os byddwch chi’n ailgyflwyno’ch deiseb gydag enw llawn a manylion cyswllt, efallai y gallwn ei chymeradwyo.",
          false
        ],
        "libellous" =>[
          "Confidential, libellous, false, defamatory or references a court case",
          "It included potentially confidential, libellous, false or defamatory information, or a reference to a case which is active in the UK courts.",
          "Roedd yn cynnwys gwybodaeth a allai fod yn gyfrinachol, yn enllibus, yn ffug neu’n ddifenwol, neu’n cyfeirio at achos sy’n weithredol yn llysoedd y DU.",
          true
        ],
        "offensive" =>[
          "Offensive, nonsense, joke or advert",
          "It’s offensive, nonsense, a joke, or an advert.",
          "Mae’n sarhaus, yn nonsens, yn jôc neu’n hysbyseb.",
          true
        ],
        "bad-address" =>[
          "Petitioner location",
          "We can only accept petitions from people who live in Wales or organisations with a base in Wales.",
          "Dim ond deisebau a gyflwynir gan bobl sy’n byw yng Nghymru neu sefydliadau sydd â chanolfan yng Nghymru y gallwn ni eu derbyn.",
          false
        ],
        "not-suitable"  =>[
          "Not suitable",
          "It included issues relating to an issue for which a petition is not the appropriate channel, or personal information which it would not be appropriate to publish.",
          "Roedd yn ymwneud â materion nad yw’n briodol ymdrin â nhw mewn deiseb, neu’n cynnwys gwybodaeth bersonol na fyddai’n briodol ei chyhoeddi.",
          true
        ]
      }.each do |code, (title, english, welsh, hidden)|
        RejectionReason.create!(
          code: code,
          title: title,
          description_en: english,
          description_cy: welsh,
          hidden: hidden
        )
      end
    end

    add_index :rejection_reasons, :code, unique: true
    add_index :rejection_reasons, :title, unique: true
    add_foreign_key :rejections, :rejection_reasons, column: "code", primary_key: "code"
  end
end
