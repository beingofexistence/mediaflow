# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HTTP, feature_category: :shared do
  let(:default_options) do
    {
      allow_local_requests: false,
      deny_all_requests_except_allowed: false,
      dns_rebinding_protection_enabled: true,
      outbound_local_requests_allowlist: [],
      silent_mode_enabled: false
    }
  end

  describe '.get' do
    it 'calls Gitlab::HTTP_V2.get with default options' do
      expect(Gitlab::HTTP_V2).to receive(:get).with('/path', default_options)

      described_class.get('/path')
    end

    context 'when passing allow_object_storage:true' do
      before do
        allow(ObjectStoreSettings).to receive(:enabled_endpoint_uris).and_return([URI('http://example.com')])
      end

      it 'calls Gitlab::HTTP_V2.get with default options and extra_allowed_uris' do
        expect(Gitlab::HTTP_V2).to receive(:get)
          .with('/path', default_options.merge(extra_allowed_uris: [URI('http://example.com')]))

        described_class.get('/path', allow_object_storage: true)
      end
    end
  end

  describe '.try_get' do
    it 'calls .get' do
      expect(described_class).to receive(:get).with('/path', {})

      described_class.try_get('/path')
    end

    it 'returns nil when .get raises an error' do
      expect(described_class).to receive(:get).and_raise(SocketError)

      expect(described_class.try_get('/path')).to be_nil
    end
  end

  describe '.perform_request' do
    context 'when sending a GET request' do
      it 'calls Gitlab::HTTP_V2.get with default options' do
        expect(Gitlab::HTTP_V2).to receive(:get).with('/path', default_options)

        described_class.perform_request(Net::HTTP::Get, '/path', {})
      end
    end

    context 'when sending a LOCK request' do
      it 'raises ArgumentError' do
        expect do
          described_class.perform_request(Net::HTTP::Lock, '/path', {})
        end.to raise_error(ArgumentError, "Unsupported HTTP method: 'lock'.")
      end
    end
  end

  context 'when the FF use_gitlab_http_v2 is disabled' do
    before do
      stub_feature_flags(use_gitlab_http_v2: false)
    end

    describe '.get' do
      it 'calls Gitlab::LegacyHTTP.get with default options' do
        expect(Gitlab::LegacyHTTP).to receive(:get).with('/path', {})

        described_class.get('/path')
      end
    end

    describe '.try_get' do
      it 'calls .get' do
        expect(described_class).to receive(:get).with('/path', {})

        described_class.try_get('/path')
      end

      it 'returns nil when .get raises an error' do
        expect(described_class).to receive(:get).and_raise(SocketError)

        expect(described_class.try_get('/path')).to be_nil
      end
    end

    describe '.perform_request' do
      it 'calls Gitlab::LegacyHTTP.perform_request with default options' do
        expect(Gitlab::LegacyHTTP).to receive(:perform_request).with(Net::HTTP::Get, '/path', {})

        described_class.perform_request(Net::HTTP::Get, '/path', {})
      end
    end
  end
end
