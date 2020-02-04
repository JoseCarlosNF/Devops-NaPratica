# -*- mode: ruby -*-
# vi: set ft=ruby :

exec { "apt-update":
	command => "/usr/bin/apt-get update"
}

package { "mysql-server":
	ensure 	=> installed,
	require => Exec["apt-update"]
}

file { "mysql-allow-acess":
	path    => "/etc/mysql/conf.d/allow_external.cnf",
	owner   => mysql,
	group   => mysql,
	mode    => '0644',
	content => template("vagrant/manifests/allow_external.cnf"),
	require => Package["mysql-server"]
  notify  => Service["mysql"]
}

service { "mysql":
	ensure     => running,
	enable     => true,
  hasstatus  => true,
  hasrestart => true,
	require    => Package["mysql-server"]
}

exec { "loja-schema":
  unless  => "mysql -u root loja_schema",
  command => "mysqladmin -u root create loja_schema",
  path    => "/usr/bin/",
  require => Service["mysql"]
}

exec { "remove-anonymous-user":
  command => "mysql -u root -e \"DELETE FROM mysql.user \
                                 WHERE user=’’; \
                                 FLUSH PRIVILEGES\"",
  onlyif  => "mysql -u ’ ’",
  path    => "/usr/bin",
  require => Service["mysql"]
}

exec { "loja-user":
  unless  => "mysql -u loja -p lojasecret loja_schema",
  command => "mysql -u root -e \"GRANT ALL PRIVILEGES ON \
                                 loja_schema.* TO ’loja’@’%’ \
                                 IDENTIFIED BY ’lojasecret’;\"",
  path    => "/usr/bin/",
  require => Exec["loja-schema"]
}
