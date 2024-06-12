# frozen_string_literal: true

require 'spec_helper'

key1 = Faker::Lorem.word
key2 = Faker::Lorem.word
key3 = Faker::Lorem.word
key4 = Faker::Lorem.word
key5 = Faker::Lorem.word

val1 = Faker::Lorem.sentence
val2 = Faker::Lorem.sentence(word_count: 10)
val3 = Faker::Lorem.sentence(word_count: 100)
val4 = rand(1..10_000)
val5 = rand(1.69..10_000.69)

describe RubyKV::DiskStore do
  let(:test_db_file) { test_db_file_path }

  subject { described_class.new(test_db_file) }

  describe '#PUT command' do
    it 'Puts a given kv pair into the kv_store. returns "OK" if succesfull, else returns and error' do
      expect(subject.put(key1, val1)).to eq('OK')
      expect(subject.put(key2, val2)).to eq('OK')
      expect(subject.put(key3, val3)).to eq('OK')
      expect(subject.put(key4, val4)).to eq('OK')
      expect(subject.put(key5, val5)).to eq('OK')
    end
  end

  describe '#GET command' do
    context 'When the key does not exist' do
      it 'returns "NOT FOUND"' do
        expect(subject.get('cool_key')).to eq('NOT FOUND')
      end
    end

    context 'When the key exists' do
      it 'returns the keys value' do
        expect(subject.get(key1)).to eq(val1)
        expect(subject.get(key2)).to eq(val2)
        expect(subject.get(key3)).to eq(val3)
        expect(subject.get(key4)).to eq(val4)
        expect(subject.get(key5)).to eq(val5)
      end
    end
  end

  describe '#DEL command' do
    context 'When the key does not exist' do
      it 'returns "NOT FOUND"' do
        expect(subject.delete('cool_key')).to eq('NOT FOUND')
      end
    end

    context 'When the key exists' do
      it 'returns "OK"' do
        expect(subject.delete(key1)).to eq('OK')
        expect(subject.delete(key2)).to eq('OK')
        expect(subject.delete(key3)).to eq('OK')
      end
    end
  end

  describe '#KEYS command' do
    it 'returns all keys in the kv_store. if no keys, returns empty array' do
      expect(subject.keys.length).to eq(2)
      expect(subject.keys).to eq([key4, key5])
    end
  end

  describe '#WIPE command' do
    it 'deletes all data from kv_store. returns "OK" if no error, else returns error' do
      expect(subject.wipe).to eq('OK')
    end
  end
end
