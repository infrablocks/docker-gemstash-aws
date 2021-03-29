require 'spec_helper'

describe 'entrypoint' do
  metadata_service_url = 'http://metadata:1338'
  s3_endpoint_url = 'http://s3:4566'
  s3_bucket_region = 'us-east-1'
  s3_bucket_name = 'bucket'
  s3_bucket_path = 's3://bucket'
  s3_env_file_object_path = 's3://bucket/env-file.env'

  environment = {
    'AWS_METADATA_SERVICE_URL' => metadata_service_url,
    'AWS_ACCESS_KEY_ID' => "...",
    'AWS_SECRET_ACCESS_KEY' => "...",
    'AWS_S3_ENDPOINT_URL' => s3_endpoint_url,
    'AWS_S3_BUCKET_REGION' => s3_bucket_region,
    'AWS_S3_ENV_FILE_OBJECT_PATH' => s3_env_file_object_path
  }
  image = 'gemstash-aws:latest'
  extra = {
    'Entrypoint' => '/bin/sh',
    'HostConfig' => {
      'NetworkMode' => 'docker_gemstash_aws_test_default'
    }
  }

  before(:all) do
    set :backend, :docker
    set :env, environment
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  describe 'by default' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path)

      execute_docker_entrypoint(
        started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'runs gemstash' do
      expect(process('\{gemstash\} puma ')).to(be_running)
    end

    it 'runs with the gemstash user' do
      expect(process('\{gemstash\} puma ').user)
        .to(eq('gemstash'))
    end

    it 'runs with the gemstash group' do
      expect(process('\{gemstash\} puma ').group)
        .to(eq('gemstash'))
    end

    it 'uses the local storage adapter' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:storage_adapter: "local"/))
    end

    it 'uses a base path of /var/opt/gemstash' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:base_path: "\/var\/opt\/gemstash"/))
    end

    it 'does not include an s3 path option' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .not_to(match(/:s3_path:/))
    end

    it 'does not include an AWS access key option' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .not_to(match(/:aws_access_key:/))
    end

    it 'does not include an AWS secret access key option' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .not_to(match(/:aws_secret_access_key:/))
    end

    it 'does not include a bucket name option' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .not_to(match(/:bucket_name:/))
    end

    it 'does not include a region option' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .not_to(match(/:region:/))
    end

    it 'uses the memory cache type' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:cache_type: "memory"/))
    end

    it 'uses a max size of 500 for the cache' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:cache_max_size: 500/))
    end

    it 'uses an expiration of 30 minutes for the cache' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:cache_expiration: 1800/))
    end

    it 'binds on all addresses on port 9292' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:bind: "tcp:\/\/0\.0\.0\.0:9292"/))
    end

    it 'does not include a puma threads option' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .not_to(match(/:puma_threads:/))
    end

    it 'does not include a puma workers option' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .not_to(match(/:puma_workers:/))
    end

    it 'does not include the protected fetch option' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .not_to(match(/:protected_fetch:/))
    end

    it 'uses a fetch timeout of 20 seconds' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:fetch_timeout: 20/))
    end

    it 'does not include the ignore gemfile source option' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .not_to(match(/:ignore_gemfile_source:/))
    end

    it 'does not include a rubygems URL' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .not_to(match(/:rubygems_url:/))
    end
  end

  describe 'with local storage adapter configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'GEMSTASH_BASE_PATH' => '/data'
        })

      execute_command("mkdir /data")
      execute_command("chown gemstash:gemstash /data")

      execute_docker_entrypoint(
        started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided base path' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:base_path: "\/data"/))
    end
  end

  describe 'with s3 storage adapter configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'GEMSTASH_STORAGE_ADAPTER' => 's3',
          'GEMSTASH_S3_PATH' => 'artifacts',
          'GEMSTASH_AWS_ACCESS_KEY' => '...',
          'GEMSTASH_AWS_SECRET_ACCESS_KEY' => '...',
          'GEMSTASH_BUCKET_NAME' => s3_bucket_name,
          'GEMSTASH_REGION' => s3_bucket_region
        })

      execute_docker_entrypoint(
        started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the s3 storage adapter' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:storage_adapter: "s3"/))
    end

    it 'uses the provided s3 path' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:s3_path: "artifacts"/))
    end

    it 'uses the provided AWS access key' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:aws_access_key: "..."/))
    end

    it 'uses the provided AWS secret access key' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:aws_secret_access_key: "..."/))
    end

    it 'uses the provided bucket name' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:bucket_name: "#{s3_bucket_name}"/))
    end

    it 'uses the provided region' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:region: "#{s3_bucket_region}"/))
    end
  end

  describe 'with general cache configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'GEMSTASH_CACHE_MAX_SIZE' => '1000',
          'GEMSTASH_CACHE_EXPIRATION' => '3600'
        })

      execute_docker_entrypoint(
        started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided max cache size' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:cache_max_size: 1000/))
    end

    it 'uses the provided cache expiration' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:cache_expiration: 3600/))
    end
  end

  describe 'with memcached cache configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'GEMSTASH_CACHE_TYPE' => 'memcached',
          'GEMSTASH_MEMCACHED_SERVERS' => 'c1.local:11211,c2.local:11211'
        })

      execute_docker_entrypoint(
        started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the memcached cache type' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:cache_type: "memcached"/))
    end

    it 'uses the provided memcached servers' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:memcached_servers: "c1.local:11211,c2.local:11211"/))
    end
  end

  describe 'with server configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'GEMSTASH_BIND' => 'tcp://0.0.0.0:4242',
          'GEMSTASH_PUMA_THREADS' => "32",
          'GEMSTASH_PUMA_WORKERS' => "2"
        })

      execute_docker_entrypoint(
        started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided bind configuration' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:bind: "tcp:\/\/0\.0\.0\.0:4242"/))
    end

    it 'uses the provided puma threads configuration' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:puma_threads: 32/))
    end

    it 'uses the provided puma workers configuration' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:puma_workers: 2/))
    end
  end

  describe 'with fetch configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'GEMSTASH_PROTECTED_FETCH_ENABLED' => 'yes',
          'GEMSTASH_FETCH_TIMEOUT' => '30'
        })

      execute_docker_entrypoint(
        started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'enables protected fetch when requested' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:protected_fetch: true/))
    end

    it 'uses the provided fetch timeout' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:fetch_timeout: 30/))
    end
  end

  describe 'with database configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'GEMSTASH_DB_ADAPTER' => 'postgres',
          'GEMSTASH_DB_URL' => 'postgres://user:password@db/user',
          'GEMSTASH_DB_CONNECTION_OPTIONS' => "{connect_timeout: 60}"
        })

      execute_docker_entrypoint(
        started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided database adapter' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:db_adapter: "postgres"/))
    end

    it 'uses the provided database URL' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:db_url: "postgres:\/\/user:password@db\/user"/))
    end

    it 'uses the provided database connection options' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:db_connection_options: {connect_timeout: 60}/))
    end
  end

  describe 'with miscellaneous configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'GEMSTASH_IGNORE_GEMFILE_SOURCE' => 'yes',
          'GEMSTASH_RUBYGEMS_URL' => 'https://gems.example.com'
        })

      execute_docker_entrypoint(
        started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'ignores gemfile source' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:ignore_gemfile_source: true/))
    end

    it 'uses the provided rubygems URL' do
      expect(file('/opt/gemstash/conf/gemstash.yml').content)
        .to(match(/:rubygems_url: "https:\/\/gems\.example\.com"/))
    end
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end

  def create_env_file(opts)
    create_object(opts
                    .merge(content: (opts[:env] || {})
                      .to_a
                      .collect { |item| " #{item[0]}=\"#{item[1]}\"" }
                      .join("\n")))
  end

  def execute_command(command_string)
    command = command(command_string)
    exit_status = command.exit_status
    unless exit_status == 0
      raise RuntimeError,
            "\"#{command_string}\" failed with exit code: #{exit_status}"
    end
    command
  end

  def create_object(opts)
    execute_command('aws ' +
                      "--endpoint-url #{opts[:endpoint_url]} " +
                      's3 ' +
                      'mb ' +
                      "#{opts[:bucket_path]} " +
                      "--region \"#{opts[:region]}\"")
    execute_command("echo -n #{Shellwords.escape(opts[:content])} | " +
                      'aws ' +
                      "--endpoint-url #{opts[:endpoint_url]} " +
                      's3 ' +
                      'cp ' +
                      '- ' +
                      "#{opts[:object_path]} " +
                      "--region \"#{opts[:region]}\" " +
                      '--sse AES256')
  end

  def execute_docker_entrypoint(opts)
    logfile_path = '/tmp/docker-entrypoint.log'
    args = (opts[:arguments] || []).join(' ')

    execute_command(
      "docker-entrypoint.sh #{args} > #{logfile_path} 2>&1 &")

    begin
      Octopoller.poll(timeout: 5) do
        docker_entrypoint_log = command("cat #{logfile_path}").stdout
        docker_entrypoint_log =~ /#{opts[:started_indicator]}/ ?
          docker_entrypoint_log :
          :re_poll
      end
    rescue Octopoller::TimeoutError => e
      puts command("cat #{logfile_path}").stdout
      raise e
    end
  end
end
