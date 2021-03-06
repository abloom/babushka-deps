dep 'passenger deploy repo' do
  requires [
    'passenger deploy repo exists',
    'passenger deploy repo hooks',
    'passenger deploy repo always receives'
  ]
end

dep 'passenger deploy repo always receives' do
  requires 'passenger deploy repo exists'
  met? { in_dir(var(:passenger_repo_root)) { shell("git config receive.denyCurrentBranch") == 'ignore' } }
  meet { in_dir(var(:passenger_repo_root)) { shell("git config receive.denyCurrentBranch ignore") } }
end

dep 'passenger deploy repo hooks' do
  requires 'passenger deploy repo exists'
  met? {
    %w[pre-receive post-receive].all? {|hook_name|
      (var(:passenger_repo_root) / ".git/hooks/#{hook_name}").executable? &&
      Babushka::Renderable.new(var(:passenger_repo_root) / ".git/hooks/#{hook_name}").from?(dependency.load_path.parent / "git/deploy-repo-#{hook_name}")
    }
  }
  meet {
    in_dir var(:passenger_repo_root), :create => true do
      %w[pre-receive post-receive].each {|hook_name|
        render_erb "git/deploy-repo-#{hook_name}", :to => ".git/hooks/#{hook_name}"
        shell "chmod +x .git/hooks/#{hook_name}"
      }
    end
  }
end

dep 'passenger deploy repo exists' do
  requires 'git'
  define_var :passenger_repo_root, :default => "~/current"
  met? { (var(:passenger_repo_root) / '.git').dir? }
  meet {
    in_dir var(:passenger_repo_root), :create => true do
      shell "git init"
    end
  }
end

dep 'github token set' do
  met? { !shell('git config --global github.token').blank? }
  meet { shell("git config --global github.token '#{var(:github_token)}'")}
end
