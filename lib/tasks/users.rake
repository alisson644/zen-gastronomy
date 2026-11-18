namespace :users do
  desc "Promove um usuário a administrador do sistema: bin/rails users:make_admin EMAIL=fulano@x.com (ou users:make_admin[fulano@x.com])"
  task :make_admin, [ :email ] => :environment do |_task, args|
    email = args[:email] || ENV["EMAIL"]
    abort "Informe o e-mail: bin/rails users:make_admin EMAIL=fulano@x.com" if email.blank?

    user = User.find_by!(email: email)
    user.update!(role: Role.admin!)
    puts "#{user.email} agora é Administrador do sistema."
  end
end
