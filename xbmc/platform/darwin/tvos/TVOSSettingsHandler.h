#pragma once
/*
 *      Copyright (C) 2015 Team MrMC
 *      https://github.com/MrMC
 *
 *  This Program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  This Program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with MrMC; see the file COPYING.  If not, see
 *  <http://www.gnu.org/licenses/>.
 *
 */

#include "settings/lib/ISettingCallback.h"

class CTVOSInputSettings : public ISettingCallback
{
 public:
  static CTVOSInputSettings& GetInstance();

  void Initialize();

    virtual void OnSettingChanged(std::shared_ptr<const CSetting> setting) override;

private:
  CTVOSInputSettings();
  CTVOSInputSettings(CTVOSInputSettings const& );
  CTVOSInputSettings& operator=(CTVOSInputSettings const&);

  static CTVOSInputSettings* m_instance;
};
