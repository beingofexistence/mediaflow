<?php

// Pandora FMS - https://pandorafms.com
// ==================================================
// Copyright (c) 20012 Pandora FMS
// Please see https://pandorafms.com/community/ for full contribution list
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation for version 2.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// Don't start a session before this import.
// The session is configured and started inside the config process.
require_once '../../include/config.php';

if (is_metaconsole() === true) {
    $config['requirements_use_base_url'] = true;
}

require_once $config['homedir'].'/operation/visual_console/public_view.php';
