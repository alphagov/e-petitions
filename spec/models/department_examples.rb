RSpec.shared_examples_for "a model with departments" do
  let(:table_name) { described_class.table_name }
  let(:connection) { described_class.connection }
  let(:indexes) { connection.indexes(table_name) }
  let(:index) { indexes.detect { |i| i.name == "index_#{table_name}_on_departments" } }

  it { is_expected.to have_db_column(:departments).of_type(:integer).with_options(array: true, null: false, default: []) }

  it "indexes the departments column using a gin index" do
    expect(index).to be_present
    expect(index.using).to eq(:gin)
  end

  it "validates the existence of the departments" do
    subject.update(departments: [999])
    expect(subject.errors[:departments]).to eq(["The submitted departments were invalid - please reselect and try again"])
  end

  let(:factory) { described_class.model_name.singular.to_sym }

  describe ".for_department" do
    let!(:department_1) { FactoryBot.create(:department) }
    let!(:department_2) { FactoryBot.create(:department) }
    let!(:model_1) { FactoryBot.create(factory, departments: []) }
    let!(:model_2) { FactoryBot.create(factory, departments: [department_1.id]) }
    let!(:model_3) { FactoryBot.create(factory, departments: [department_1.id, department_2.id]) }
    let!(:model_4) { FactoryBot.create(factory, departments: [department_2.id]) }

    context "when using no departments" do
      it "returns all models" do
        expect(described_class.for_department([])).to include(model_1, model_2, model_3, model_4)
      end
    end

    context "when using one department" do
      it "returns all models assigned to that department" do
        expect(described_class.for_department([department_1.id])).to include(model_2, model_3)
      end

      it "doesn't return models that aren't assigned to that department" do
        expect(described_class.for_department([department_1.id])).not_to include(model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.for_department([department_1.id])).not_to include(model_1)
      end
    end

    context "when using multiple departments" do
      it "returns all models assigned to both departments" do
        expect(described_class.for_department([department_1.id, department_2.id])).to include(model_3)
      end

      it "doesn't return models that are assigned to only one of the departments" do
        expect(described_class.for_department([department_1.id, department_2.id])).not_to include(model_2, model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.for_department([department_1.id, department_2.id])).not_to include(model_1)
      end
    end
  end

  describe ".all_departments" do
    let!(:department_1) { FactoryBot.create(:department) }
    let!(:department_2) { FactoryBot.create(:department) }
    let!(:model_1) { FactoryBot.create(factory, departments: []) }
    let!(:model_2) { FactoryBot.create(factory, departments: [department_1.id]) }
    let!(:model_3) { FactoryBot.create(factory, departments: [department_1.id, department_2.id]) }
    let!(:model_4) { FactoryBot.create(factory, departments: [department_2.id]) }

    context "when using no departments" do
      it "returns all models" do
        expect(described_class.for_department([])).to include(model_1, model_2, model_3, model_4)
      end
    end

    context "when using one department" do
      it "returns all models assigned to that department" do
        expect(described_class.all_departments([department_1.id])).to include(model_2, model_3)
      end

      it "doesn't return models that aren't assigned to that department" do
        expect(described_class.all_departments([department_1.id])).not_to include(model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.all_departments([department_1.id])).not_to include(model_1)
      end
    end

    context "when using multiple departments" do
      it "returns all models assigned to both departments" do
        expect(described_class.all_departments([department_1.id, department_2.id])).to include(model_3)
      end

      it "doesn't return models that are assigned to only one of the departments" do
        expect(described_class.all_departments([department_1.id, department_2.id])).not_to include(model_2, model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.all_departments([department_1.id, department_2.id])).not_to include(model_1)
      end
    end
  end

  describe ".any_departments" do
    let!(:department_1) { FactoryBot.create(:department) }
    let!(:department_2) { FactoryBot.create(:department) }
    let!(:model_1) { FactoryBot.create(factory, departments: []) }
    let!(:model_2) { FactoryBot.create(factory, departments: [department_1.id]) }
    let!(:model_3) { FactoryBot.create(factory, departments: [department_1.id, department_2.id]) }
    let!(:model_4) { FactoryBot.create(factory, departments: [department_2.id]) }

    context "when using no departments" do
      it "returns no models" do
        expect(described_class.any_departments([])).to be_empty
      end
    end

    context "when using one department" do
      it "returns all models assigned to that department" do
        expect(described_class.any_departments([department_1.id])).to include(model_2, model_3)
      end

      it "doesn't return models that aren't assigned to that department" do
        expect(described_class.any_departments([department_1.id])).not_to include(model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.any_departments([department_1.id])).not_to include(model_1)
      end
    end

    context "when using multiple departments" do
      it "returns all models assigned to both departments" do
        expect(described_class.any_departments([department_1.id, department_2.id])).to include(model_3)
      end

      it "returns models that are assigned with only one of the departments" do
        expect(described_class.any_departments([department_1.id, department_2.id])).to include(model_2, model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.any_departments([department_1.id, department_2.id])).not_to include(model_1)
      end
    end
  end

  describe ".with_department" do
    let!(:department) { FactoryBot.create(:department) }
    let!(:model_1) { FactoryBot.create(factory, departments: [department.id]) }
    let!(:model_2) { FactoryBot.create(factory, departments: []) }

    it "returns assigned models" do
      expect(described_class.with_department).to include(model_1)
    end

    it "doesn't return unassigned models" do
      expect(described_class.with_department).not_to include(model_2)
    end
  end

  describe ".without_department" do
    let!(:department) { FactoryBot.create(:department) }
    let!(:model_1) { FactoryBot.create(factory, departments: []) }
    let!(:model_2) { FactoryBot.create(factory, departments: [department.id]) }

    it "returns unassigned models" do
      expect(described_class.without_department).to include(model_1)
    end

    it "doesn't return assigned models" do
      expect(described_class.without_department).not_to include(model_2)
    end
  end

  describe ".normalize_departments" do
    it "removes non-numeric strings" do
      expect(described_class.normalize_departments(["foo"])).to eq([])
    end

    it "removes zero strings" do
      expect(described_class.normalize_departments(["0"])).to eq([])
    end

    it "removes nil values" do
      expect(described_class.normalize_departments([nil])).to eq([])
    end

    it "converts strings to integers" do
      expect(described_class.normalize_departments(["1"])).to eq([1])
    end
  end

  describe "#normalize_departments" do
    it "delegates to the class method" do
      expect(described_class).to receive(:normalize_departments).with(["foo"]).and_call_original
      expect(subject.normalize_departments(["foo"])).to eq([])
    end
  end

  describe "#depts" do
    before do
      fco = FactoryBot.create(:department, :fco)
      dfid = FactoryBot.create(:department, :dfid)

      subject.departments = [fco.id, dfid.id]
    end

    it "returns an array of Department instances" do
      expect(subject.departments).to contain_exactly(
        an_object_having_attributes(name: "Department for International Development"),
        an_object_having_attributes(name: "Foreign and Commonwealth Office")
      )
    end
  end

  describe "#departments=" do
    it "normalizes department values" do
      subject.departments = ["foo", nil, "0", 0, "1", 2]
      expect(subject[:departments]).to eq([1, 2])
    end
  end

  describe "#department_names" do
    before do
      fco = FactoryBot.create(:department, :fco)
      dfid = FactoryBot.create(:department, :dfid)

      subject.departments = [fco.id, dfid.id]
    end

    it "returns the array of department names" do
      expect(subject.department_names).to eq([
        "Department for International Development",
        "Foreign and Commonwealth Office"
      ])
    end
  end
end
