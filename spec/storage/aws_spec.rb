require 'spec_helper'

describe CarrierWave::Storage::AWS do
  let(:credentials) { { access_key_id: 'abc', secret_access_key: '123' } }
  let(:uploader)    { mock(:uploader, aws_credentials: credentials) }
  let(:storage)     { described_class.new(uploader) }

  describe '#connection' do
    it 'instantiates a new connection' do
      AWS::S3.should_receive(:new).with(credentials)

      storage.connection
    end

    it 'caches connections by credentials' do
      AWS::S3.should_receive(:new).with(credentials).and_return(mock)

      storage.connection.should === storage.connection
    end
  end
end

describe CarrierWave::Storage::AWS::File do
  let(:file)       { mock(:file, read: '0101010') }
  let(:objects)    { { 'files/1/file.txt' => file } }
  let(:bucket)     { mock(:bucket, objects: objects) }
  let(:connection) { mock(:connection, buckets: { 'example-com' => bucket }) }
  let(:uploader)   { mock(:uploader, aws_bucket: 'example-com') }
  let(:storage)    { mock(:storage, connection: connection) }
  let(:path)       { 'files/1/file.txt' }

  subject(:aws_file) { described_class.new(uploader, storage, path) }

  describe '#read' do
    it 'reads from the remote file object' do
      aws_file.read.should == '0101010'
    end
  end

  describe '#authenticated_url' do
    it 'requests a url for reading with the configured expiration' do
      uploader.stub(aws_authenticated_url_expiration: 60)

      file.should_receive(:url_for).with(:read, expires: 60)

      aws_file.authenticated_url
    end
  end

  describe '#url' do
    it 'requests a public url if acl is public readable' do
      uploader.stub(aws_acl: :public_read)
      file.should_receive(:public_url)

      aws_file.url
    end

    it 'requests an authenticated url if acl is not public readable' do
      uploader.stub(aws_acl: :private, aws_authenticated_url_expiration: 60)

      file.should_receive(:url_for)

      aws_file.url
    end
  end
end
