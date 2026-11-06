# frozen_string_literal: true

require 'dirload'
require 'tmpdir'
require_relative '../../../lib/pages/pages'

RSpec.describe Rain::Pages do
  subject(:pages) { described_class.new(metadata: dirload(File.join(@dir, 'app'))) }

  around do |example|
    Dir.mktmpdir do |dir|
      @dir = File.realpath(dir)
      Dir.chdir(dir) { example.run }
    end
  end

  def write(path, content)
    file_path = File.join(@dir, 'app', 'pages', path)
    FileUtils.mkdir_p(File.dirname(file_path))
    File.write(file_path, content)
  end

  before do
    write('docs/_basics/_1-getting-started.md', "---\ntitle: Getting started\n---\n\n# Getting started\n")
    write('docs/_basics/_2-setup.rd', "---\ntitle: Setup\n---\n\n# Setup\n\n<!-- list: folder: 'basics' -->\n<!-- :list -->\n")
    write('home.md', "# Home\n")
  end

  it 'makes URL paths from the path under app/pages, without underscored segments' do
    expect(described_class.url_path(file_path: "#{described_class.pages_path}/docs/_1&_guides/_10-deploy.md")).to eq('/docs/deploy')
  end

  it 'has no URL path for files outside app/pages' do
    expect(described_class.url_path(file_path: File.expand_path('app/home/syntax.md', Dir.pwd))).to be_nil
  end

  it 'maps URL paths to files' do
    expect(pages.url_paths.keys).to contain_exactly('/docs/getting-started', '/docs/setup', '/home')
  end

  it "adds each page's URL path to Raindown's metadata as its path" do
    expect(pages.list(folder: 'basics').map { [it.title, it.folder, it.order, it.path] })
      .to eq([['Getting started', 'basics', 1, '/docs/getting-started'], ['Setup', 'basics', 2, '/docs/setup']])
  end

  it 'renders a page by URL path with Raindown, listing files by URL path' do
    page = pages.page(path: '/docs/setup')

    expect(page.metadata).to include(title: 'Setup', path: '/docs/setup')
    expect(page.html).to include('<h1 id="setup">', '<a href="/docs/getting-started">Getting started</a>')
    expect(page.html).not_to include('list:', '<strong>')
  end

  it "leaves directives out of a listed page's content" do
    content = pages.list(folder: 'basics').last.content

    expect(content).to include('<h1 id="setup">')
    expect(content).not_to include('list:', '<strong>')
  end

  it 'renders the home page for /' do
    expect(pages.page(path: '/').html).to include('<h1 id="home">')
    expect(pages.page(path: '/missing')).to be_nil
  end
end
