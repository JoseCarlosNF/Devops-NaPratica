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
	content => "[mysqld]\n bind-address = 0.0.0.0\n",
	require => Package["mysql-server"],
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
  unless  => "mysql -uroot loja_schema",
  command => "mysqladmin -uroot create loja_schema",
  path    => "/usr/bin/",
  require => Service["mysql"]
}

exec { "remove-anonymous-user":
  command => "mysql -uroot -e \"DELETE FROM mysql.user WHERE user=' '; FLUSH PRIVILEGES\"",
  onlyif  => "mysql -u' '",
  path    => "/usr/bin",
  require => Service["mysql"]
}

exec { "loja-user":
  unless  => "mysql -uloja -plojasecret loja_schema",
  command => "mysql -uroot -e \"GRANT ALL PRIVILEGES ON loja_schema.* TO 'loja'@'localhost' IDENTIFIED BY 'lojasecret';\"",
  path    => "/usr/bin/",
  require => Exec["loja-schema"]
}
