#pragma once

// local files
#include "mydialog.hpp"
#include "resource.h"

// mfc
#include <afxwin.h>

// windows
#include <windows.h>

// std
#include <iostream>

struct MyApp final : public CWinApp {
	MyApp() = default;

	virtual BOOL InitInstance() override {
		if(!CWinApp::InitInstance()){
			return FALSE;
		}
		MyDialog dlg;
		m_pMainWnd = &dlg;
		const INT_PTR nResponse = dlg.DoModal();
		if (nResponse == -1) {
			// FIXME: get extended error message
			std::cerr << "Error: Dialog creation failed\n";
		}
		return FALSE;
	}

};

