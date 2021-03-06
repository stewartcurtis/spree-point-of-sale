require 'spec_helper'

describe Spree::Stock::PosAvailabilityValidator do
  let(:country) { Spree::Country.create!(:name => 'mk_country', :iso_name => "mk") }
  let(:state) { country.states.create!(:name => 'mk_state') }
  let(:store) { Spree::StockLocation.create!(:name => 'store', :store => true, :address1 => "home", :address2 => "town", :city => "delhi", :zipcode => "110034", :country_id => country.id, :state_id => state.id, :phone => "07777676767") }
  
  before do
    @order = Spree::Order.create!(:is_pos => true)
    @product = Spree::Product.create!(:name => 'test-product', :price => 10)
    @variant = @product.master
    @line_item = @order.line_items.build(:variant_id => @variant.id, :quantity => 3)
    @line_item.price = @product.price
    @shipment = @order.shipments.create!
    @line_item.stub(:order).and_return(@order)
    @order.stub(:shipment).and_return(@shipment)
  end

  describe 'ensures stock location' do
    it 'presence' do
      @line_item.order.shipment.stock_location.should be_nil
      @line_item.save
      @line_item.errors[:stock_location].should eq(['No Active Store Associated'])
    end

    it 'as active' do
      store.update_attributes(:active => false, :store => true)
      @shipment.stub(:stock_location).and_return(store)
      @line_item.save
      @line_item.errors[:stock_location].should eq(['No Active Store Associated'])
    end

    it 'as store' do
      store.update_attributes(:active => true, :store => false)
      @shipment.stub(:stock_location).and_return(store)
      @line_item.save
      @line_item.errors[:stock_location].should eq(['No Active Store Associated'])
    end

    it 'as store' do
      store.update_attributes(:active => true, :store => true)
      @shipment.stub(:stock_location).and_return(store)
      @line_item.save
      @line_item.errors[:stock_location].should be_blank
    end
  end

  describe 'checks for supply' do
    before do
      store.update_attributes(:active => true, :store => true)
      @shipment.stub(:stock_location).and_return(store)
    end

    it 'adds error if cant supply' do
      @line_item.save
      @line_item.errors[:quantity].should eq(['Adding More Than Available'])
    end

    it 'no error if can supply' do
      store.stock_items.update_all(:count_on_hand => 4)
      @line_item.save!
      @line_item.errors[:quantity].should be_blank
    end

    it 'finds out quantity difference' do
      @line_item.should_receive(:quantity_was).and_return(nil)
      @line_item.save
    end
  end
end 