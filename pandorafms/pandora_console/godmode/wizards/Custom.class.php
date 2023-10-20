<?php
/**
 * Custom wizard manager.
 *
 * @category   Wizard
 * @package    Pandora FMS
 * @subpackage Custom
 * @version    1.0.0
 * @license    See below
 *
 *    ______                 ___                    _______ _______ ________
 *   |   __ \.-----.--.--.--|  |.-----.----.-----. |    ___|   |   |     __|
 *  |    __/|  _  |     |  _  ||  _  |   _|  _  | |    ___|       |__     |
 * |___|   |___._|__|__|_____||_____|__| |___._| |___|   |__|_|__|_______|
 *
 * ============================================================================
 * Copyright (c) 2007-2021 Artica Soluciones Tecnologicas, http://www.artica.es
 * This code is NOT free software. This code is NOT licenced under GPL2 licence
 * You cannnot redistribute it without written permission of copyright holder.
 * ============================================================================
 */

require_once $config['homedir'].'/godmode/wizards/Wizard.main.php';
require_once $config['homedir'].'/include/functions_users.php';
require_once $config['homedir'].'/include/class/ExtensionsDiscovery.class.php';

/**
 * Implements Wizard to provide generic Custom wizard.
 */
class Custom extends Wizard
{

    /**
     * Sub-wizard to be launch (vmware,oracle...).
     *
     * @var string
     */
    public $mode;


    /**
     * Constructor.
     *
     * @param integer $page  Start page, by default 0.
     * @param string  $msg   Default message to show to users.
     * @param string  $icon  Target icon to be used.
     * @param string  $label Target label to be displayed.
     *
     * @return mixed
     */
    public function __construct(
        int $page=0,
        string $msg='Default message. Not set.',
        string $icon='/images/wizard/Custom_apps@svg.svg',
        string $label='Custom'
    ) {
        $this->setBreadcrum([]);

        $this->access = 'AW';
        $this->task = [];
        $this->msg = $msg;
        $this->icon = $icon;
        $this->class = $class_style;
        $this->label = $label;
        $this->page = $page;
        $this->url = ui_get_full_url(
            'index.php?sec=gservers&sec2=godmode/servers/discovery&wiz=custom'
        );

        return $this;
    }


    /**
     * Run wizard manager.
     *
     * @return mixed Returns null if wizard is ongoing. Result if done.
     */
    public function run()
    {
        global $config;

        // Load styles.
        parent::run();

        // Load current wiz. sub-styles.
        ui_require_css_file(
            'custom',
            ENTERPRISE_DIR.'/include/styles/wizards/'
        );

        $mode = get_parameter('mode', null);
        $extensions = new ExtensionsDiscovery('custom', $mode);
        if ($mode !== null) {
            // Load extension if exist.
            $extensions->run();
            return;
        }

        // Load classes and print selector.
        $wiz_data = $extensions->loadExtensions();

        $this->prepareBreadcrum(
            [
                [
                    'link'  => ui_get_full_url(
                        'index.php?sec=gservers&sec2=godmode/servers/discovery'
                    ),
                    'label' => __('Discovery'),
                ],
                [
                    'link'     => ui_get_full_url(
                        'index.php?sec=gservers&sec2=godmode/servers/discovery&wiz=custom'
                    ),
                    'label'    => __('Custom'),
                    'selected' => true,
                ],
            ]
        );

        // Header.
        ui_print_page_header(
            __('Custom'),
            '',
            false,
            '',
            true,
            '',
            false,
            '',
            GENERIC_SIZE_TEXT,
            '',
            $this->printHeader(true)
        );

        Wizard::printBigButtonsList($wiz_data);

        echo '<div class="app_mssg"><i>*'.__('All company names used here are for identification purposes only. Use of these names, logos, and brands does not imply endorsement.').'</i></div>';
        return $result;
    }


    /**
     * Check if section have extensions.
     *
     * @return boolean Return true if section is empty.
     */
    public function isEmpty()
    {
        $extensions = new ExtensionsDiscovery('custom');
        $listExtensions = $extensions->getExtensionsApps();
        if ($listExtensions > 0) {
            return false;
        } else {
            return true;
        }
    }


}
