# frozen_string_literal: true

require 'spec_helper'

describe 'image' do
  image = 'gemstash-aws:latest'
  extra = {
    'Entrypoint' => '/bin/sh'
  }

  before(:all) do
    set :backend, :docker
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  after(:all, &:reset_docker_backend)

  it 'puts the gemstash user in the gemstash group' do
    expect(user('gemstash'))
      .to(belong_to_primary_group('gemstash'))
  end

  it 'has the correct owning user on the gemstash directory' do
    expect(file('/opt/gemstash')).to(be_owned_by('gemstash'))
  end

  it 'has the correct owning group on the gemstash directory' do
    expect(file('/opt/gemstash')).to(be_grouped_into('gemstash'))
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end
end
