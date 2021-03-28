require 'spec_helper'

describe 'commands' do
  image = 'gemstash-aws:latest'
  extra = {
      'Entrypoint' => '/bin/sh',
  }

  before(:all) do
    set :backend, :docker
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  after(:all, &:reset_docker_backend)

  it "includes the gemstash command" do
    expect(command('gemstash --version').stdout)
        .to(match(/2\.1\.0/))
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end
end
