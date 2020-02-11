class CreateRejectionReasons < ActiveRecord::Migration[5.2]
  class RejectionReason < ActiveRecord::Base; end

  def change
    create_table :rejection_reasons do |t|
      t.string :code, limit: 30, null: false
      t.string :title, limit: 100, null: false
      t.string :description, limit: 2000, null: false
      t.boolean :hidden, null: false, default: false
      t.timestamps null: false
    end

    up_only do
      {
        "duplicate"  => ["Duplicate petition", "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue.\n\nYou are more likely to get action on this issue if you sign and share a single petition.", false],
        "irrelevant" => ["Not the Government/Parliament’s responsibility", "It’s about something that the UK Government or Parliament is not responsible for.", false],
        "no-action"  => ["Action unclear", "It’s not clear what the petition is asking the UK Government or Parliament to do.", false],
        "honours"    => ["Honours or appointments", "It’s about honours or appointments.", false],
        "fake-name"  => ["Fake name", "It was created using a fake or incomplete name.\n\nThe text of your petition meets our terms and conditions.\n\nHowever, people who create petitions are required to give their full, real name. Sorry if this wasn’t clear to you.\n\nWe are rejecting your petition for that reason, but if you resubmit your petition using your full name, we’ll be able to approve it.", false],
        "foi"        => ["FOI request", "It’s an FOI request.", false],
        "libellous"  => ["Confidential, libellous, false, defamatory or references a court case", "It included confidential, libellous, false or defamatory information, or a reference to a case which is active in the UK courts.", true],
        "offensive"  => ["Offensive, joke, nonsense or advert", "It’s offensive, nonsense, a joke, or an advert.", true]
      }.each do |code, (title, description, hidden)|
        RejectionReason.create!(code: code, title: title, description: description, hidden: hidden)
      end
    end

    add_index :rejection_reasons, :code, unique: true
    add_index :rejection_reasons, :title, unique: true
    add_foreign_key :rejections, :rejection_reasons, column: "code", primary_key: "code"
    add_foreign_key :archived_rejections, :rejection_reasons, column: "code", primary_key: "code"
  end
end
